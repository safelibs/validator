from __future__ import annotations

import argparse
import codecs
import errno
import fcntl
import hashlib
import json
import os
import pty
import re
import select
import shlex
import shutil
import signal
import struct
import subprocess
import sys
import tempfile
import termios
import time
from dataclasses import dataclass, field
from pathlib import Path
from typing import TextIO

if __package__ in {None, ""}:
    sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from tools import ValidatorError, ensure_parent, select_libraries, write_json
from tools.inventory import load_manifest
from tools.testcases import Testcase, TestcaseManifest, load_manifests


VALID_MODES = {"original", "port-04-test"}
CAST_COLUMNS = 120
CAST_ROWS = 40
CAST_HEADER_TIMESTAMP = 0
DETERMINISTIC_CAST_EVENT_INTERVAL_SECONDS = 0.001
DETERMINISTIC_TIMESTAMP = "1970-01-01T00:00:00Z"
DETERMINISTIC_DURATION_SECONDS = 0.0
VALIDATOR_XTRACE_PREFIX = "__VALIDATOR_XTRACE__ "
TMP_PATH_PATTERN = re.compile(r"/tmp/tmp\.?[A-Za-z0-9_-]+")
LS_DATE_PATTERN = re.compile(
    r"\b(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec) +\d{1,2} +\d{2}:\d{2}\b"
)
MINISIGN_PUBLIC_KEY_PATTERN = re.compile(r"-P [A-Za-z0-9+/=]+")
TRUSTED_TIMESTAMP_PATTERN = re.compile(r"timestamp:\d+")
READSTAT_TIMESTAMP_PATTERN = re.compile(r"Timestamp: \d{1,2} [A-Z][a-z]{2} \d{4} \d{2}:\d{2}")
VALIDATOR_XTRACE_MARKER_PATTERN = r"_+VALIDATOR_XTRACE__ "
VALIDATOR_XTRACE_LINE_PATTERN = re.compile(rf"^{VALIDATOR_XTRACE_MARKER_PATTERN}[^\n]*(?:\n|$)", re.MULTILINE)
VALIDATOR_XTRACE_INLINE_PATTERN = re.compile(rf"{VALIDATOR_XTRACE_MARKER_PATTERN}[^\r\n]*")


@dataclass(init=False)
class LibraryState:
    image_tags: dict[str, str] = field(default_factory=dict)
    image_errors: dict[str, str] = field(default_factory=dict)

    def __init__(
        self,
        *,
        image_tags: dict[str, str] | None = None,
        image_errors: dict[str, str] | None = None,
        image_tag: str | None = None,
    ) -> None:
        self.image_tags = dict(image_tags or {})
        if image_tag is not None and "shared" not in self.image_tags:
            self.image_tags["shared"] = image_tag
        self.image_errors = dict(image_errors or {})

    @property
    def image_tag(self) -> str | None:
        return self.image_tags.get("shared")

    @image_tag.setter
    def image_tag(self, value: str | None) -> None:
        if value is None:
            self.image_tags.pop("shared", None)
            return
        self.image_tags["shared"] = value


@dataclass(frozen=True)
class MatrixArgs:
    config: Path
    tests_root: Path
    artifact_root: Path
    override_deb_root: Path | None
    port_deb_lock: Path | None
    mode: str
    record_casts: bool
    library: list[str] | None
    list_libraries: bool


@dataclass(frozen=True)
class RunOutcome:
    exit_code: int
    timed_out: bool = False


def iso_utc_now() -> str:
    return DETERMINISTIC_TIMESTAMP


def artifact_relative_path(path: Path, artifact_root: Path) -> str:
    return path.resolve(strict=False).relative_to(artifact_root.resolve(strict=False)).as_posix()


def validate_library_name(library: str) -> str:
    if not library or library in {".", ".."}:
        raise ValidatorError(f"invalid library name: {library!r}")
    if Path(library).is_absolute() or "/" in library or "\\" in library:
        raise ValidatorError(f"invalid library name: {library!r}")
    return library


def artifact_path(artifact_root: Path, *parts: str) -> Path:
    target = artifact_root.joinpath(*parts).resolve(strict=False)
    try:
        target.relative_to(artifact_root.resolve(strict=False))
    except ValueError as exc:
        raise ValidatorError(f"artifact path escapes artifact root: {target}") from exc
    return target


def mode_artifact_parts(mode: str) -> tuple[str, ...]:
    if mode == "original":
        return ()
    if mode == "port-04-test":
        return ("port-04-test",)
    raise ValidatorError(f"unsupported mode: {mode}")


def mode_artifact_path(artifact_root: Path, mode: str, *parts: str) -> Path:
    return artifact_path(artifact_root, *mode_artifact_parts(mode), *parts)


def append_log(log_path: Path, text: str) -> None:
    ensure_parent(log_path)
    with log_path.open("a", encoding="utf-8") as handle:
        handle.write(text)


def shell_join(args: list[str]) -> str:
    return " ".join(shlex.quote(arg) for arg in args)


def normalize_log_text(text: str, replacements: dict[str, str] | None = None) -> str:
    normalized = text
    if replacements:
        for source, target in sorted(replacements.items(), key=lambda item: len(item[0]), reverse=True):
            normalized = normalized.replace(source, target)
    normalized = TMP_PATH_PATTERN.sub("/tmp/validator-tmp", normalized)
    normalized = LS_DATE_PATTERN.sub("Jan 01 00:00", normalized)
    normalized = MINISIGN_PUBLIC_KEY_PATTERN.sub("-P MINISIGN-PUBLIC-KEY", normalized)
    normalized = TRUSTED_TIMESTAMP_PATTERN.sub("timestamp:0", normalized)
    normalized = READSTAT_TIMESTAMP_PATTERN.sub("Timestamp: 01 Jan 1970 00:00", normalized)
    return normalized


def normalize_recorded_output_text(text: str, replacements: dict[str, str] | None = None) -> str:
    normalized = normalize_log_text(text, replacements)
    normalized = VALIDATOR_XTRACE_LINE_PATTERN.sub("", normalized)
    normalized = VALIDATOR_XTRACE_INLINE_PATTERN.sub("", normalized)
    return normalized


def deterministic_cast_events(text: str) -> list[tuple[float, str]]:
    chunks = text.splitlines(keepends=True) or [""]
    return [
        (round(index * DETERMINISTIC_CAST_EVENT_INTERVAL_SECONDS, 6), chunk)
        for index, chunk in enumerate(chunks)
    ]


def set_pty_size(fd: int, *, rows: int, cols: int) -> None:
    winsize = struct.pack("HHHH", rows, cols, 0, 0)
    fcntl.ioctl(fd, termios.TIOCSWINSZ, winsize)


def _kill_process_group(process: subprocess.Popen[object]) -> None:
    if process.poll() is not None:
        return
    try:
        os.killpg(process.pid, signal.SIGTERM)
    except ProcessLookupError:
        return
    try:
        process.wait(timeout=1)
    except subprocess.TimeoutExpired:
        try:
            os.killpg(process.pid, signal.SIGKILL)
        except ProcessLookupError:
            return


def _text_from_timeout_output(value: str | bytes | None) -> str:
    if value is None:
        return ""
    if isinstance(value, bytes):
        return value.decode("utf-8", "replace")
    return value


def stream_process(
    args: list[str],
    log_handle: TextIO,
    *,
    cwd: Path | None = None,
    env: dict[str, str] | None = None,
    timeout_seconds: int | float | None = None,
    log_replacements: dict[str, str] | None = None,
) -> RunOutcome:
    try:
        process = subprocess.Popen(
            args,
            cwd=cwd,
            env=env,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            encoding="utf-8",
            errors="replace",
            start_new_session=True,
        )
    except OSError as exc:
        log_handle.write(normalize_log_text(f"{type(exc).__name__}: {exc}\n", log_replacements))
        log_handle.flush()
        return RunOutcome(127)

    try:
        stdout, _ = process.communicate(timeout=timeout_seconds)
    except subprocess.TimeoutExpired as exc:
        timed_out_output = _text_from_timeout_output(exc.output)
        if timed_out_output:
            log_handle.write(normalize_log_text(timed_out_output, log_replacements))
        _kill_process_group(process)
        stdout, _ = process.communicate()
        if stdout:
            log_handle.write(normalize_log_text(stdout, log_replacements))
        log_handle.flush()
        return RunOutcome(124, timed_out=True)

    if stdout:
        log_handle.write(normalize_log_text(stdout, log_replacements))
    log_handle.flush()
    return RunOutcome(int(process.returncode or 0))


def stream_process_with_cast(
    args: list[str],
    log_handle: TextIO,
    cast_path: Path,
    *,
    cwd: Path | None = None,
    env: dict[str, str] | None = None,
    timeout_seconds: int | float | None = None,
    log_replacements: dict[str, str] | None = None,
    deterministic_cast: bool = False,
) -> RunOutcome:
    ensure_parent(cast_path)
    with cast_path.open("w", encoding="utf-8") as cast_handle:
        cast_header = {
            "version": 2,
            "width": CAST_COLUMNS,
            "height": CAST_ROWS,
            "timestamp": CAST_HEADER_TIMESTAMP,
            "env": {"TERM": "xterm-256color", "SHELL": "/bin/bash"},
        }
        cast_handle.write(json.dumps(cast_header) + "\n")

        master_fd, slave_fd = pty.openpty()
        set_pty_size(slave_fd, rows=CAST_ROWS, cols=CAST_COLUMNS)
        started = time.monotonic()
        deadline = started + float(timeout_seconds) if timeout_seconds is not None else None
        decoder = codecs.getincrementaldecoder("utf-8")("replace")
        timed_out = False
        output_parts: list[str] = []
        wrote_cast_event = False

        def write_output(text: str) -> None:
            nonlocal wrote_cast_event
            if deterministic_cast:
                output_parts.append(text)
                return
            text = normalize_log_text(text, log_replacements)
            log_handle.write(text)
            timestamp = max(0.0, time.monotonic() - started)
            cast_handle.write(json.dumps([timestamp, "o", text]) + "\n")
            wrote_cast_event = True

        def persist_output() -> None:
            nonlocal wrote_cast_event
            if deterministic_cast:
                text = normalize_recorded_output_text("".join(output_parts), log_replacements)
                if text:
                    log_handle.write(text)
                for timestamp, chunk in deterministic_cast_events(text):
                    cast_handle.write(json.dumps([timestamp, "o", chunk]) + "\n")
                wrote_cast_event = True
            elif not wrote_cast_event:
                cast_handle.write(json.dumps([max(0.0, time.monotonic() - started), "o", ""]) + "\n")
                wrote_cast_event = True
            log_handle.flush()
            cast_handle.flush()

        try:
            try:
                process = subprocess.Popen(
                    args,
                    cwd=cwd,
                    env=env,
                    stdin=slave_fd,
                    stdout=slave_fd,
                    stderr=slave_fd,
                    start_new_session=True,
                )
            except OSError as exc:
                message = f"{type(exc).__name__}: {exc}\n"
                write_output(message)
                persist_output()
                return RunOutcome(127)
            finally:
                os.close(slave_fd)

            while True:
                now = time.monotonic()
                if deadline is not None and now >= deadline and process.poll() is None and not timed_out:
                    timed_out = True
                    timeout_message = f"\nprocess timed out after {timeout_seconds} seconds\n"
                    write_output(timeout_message)
                    _kill_process_group(process)

                wait_time = 0.1
                if deadline is not None:
                    wait_time = max(0.0, min(wait_time, deadline - time.monotonic()))
                readable, _, _ = select.select([master_fd], [], [], wait_time)
                if readable:
                    try:
                        chunk = os.read(master_fd, 4096)
                    except OSError as exc:
                        if exc.errno != errno.EIO:
                            raise
                        chunk = b""
                    if chunk:
                        text = decoder.decode(chunk)
                        if text:
                            write_output(text)
                        continue

                if process.poll() is not None:
                    while True:
                        readable, _, _ = select.select([master_fd], [], [], 0)
                        if not readable:
                            break
                        try:
                            chunk = os.read(master_fd, 4096)
                        except OSError as exc:
                            if exc.errno != errno.EIO:
                                raise
                            break
                        if not chunk:
                            break
                        text = decoder.decode(chunk)
                        if text:
                            write_output(text)
                    tail = decoder.decode(b"", final=True)
                    if tail:
                        write_output(tail)
                    persist_output()
                    return RunOutcome(124 if timed_out else int(process.returncode or 0), timed_out=timed_out)
        finally:
            os.close(master_fd)


def run_logged(
    args: list[str],
    *,
    log_path: Path,
    cast_path: Path | None = None,
    cwd: Path | None = None,
    env: dict[str, str] | None = None,
    timeout_seconds: int | float | None = None,
    log_replacements: dict[str, str] | None = None,
    deterministic_cast: bool = False,
) -> RunOutcome:
    ensure_parent(log_path)
    with log_path.open("a", encoding="utf-8") as log_handle:
        log_handle.write(normalize_log_text(f"$ {shell_join(args)}\n", log_replacements))
        log_handle.flush()
        if cast_path is not None:
            return stream_process_with_cast(
                args,
                log_handle,
                cast_path,
                cwd=cwd,
                env=env,
                timeout_seconds=timeout_seconds,
                log_replacements=log_replacements,
                deterministic_cast=deterministic_cast,
            )
        return stream_process(
            args,
            log_handle,
            cwd=cwd,
            env=env,
            timeout_seconds=timeout_seconds,
            log_replacements=log_replacements,
        )


def validate_matrix_override_deb_root(root: Path) -> None:
    if not root.exists():
        raise ValidatorError(f"override deb root does not exist: {root}")
    if not root.is_dir():
        raise ValidatorError(f"override deb root must be a directory: {root}")
    if list(root.glob("*.deb")):
        raise ValidatorError(
            "--override-deb-root must point to a matrix root laid out as "
            "<override-deb-root>/<library>/*.deb"
        )


def resolve_override_deb_dir(root: Path, library: str) -> Path:
    library = validate_library_name(library)
    library_root = root / library
    if not library_root.is_dir():
        raise ValidatorError(
            f"missing override deb leaf for {library}: expected {root / library} with .deb files"
        )
    debs = sorted(library_root.glob("*.deb"))
    if not debs:
        raise ValidatorError(f"override deb leaf for {library} contains no .deb files: {library_root}")
    return library_root


def _reject_json_constant(value: str) -> None:
    raise ValueError(f"invalid JSON constant: {value}")


def _load_json_object(path: Path, *, description: str) -> dict[str, object]:
    try:
        payload = json.loads(path.read_text(), parse_constant=_reject_json_constant)
    except FileNotFoundError as exc:
        raise ValidatorError(f"missing {description}: {path}") from exc
    except ValueError as exc:
        raise ValidatorError(f"invalid {description} JSON at {path}: {exc}") from exc
    if not isinstance(payload, dict):
        raise ValidatorError(f"{description} must be a JSON object: {path}")
    return payload


def _require_string(value: object, *, field_name: str, context: str) -> str:
    if not isinstance(value, str) or not value.strip():
        raise ValidatorError(f"{field_name} must be a non-empty string in {context}")
    return value


def _require_int(value: object, *, field_name: str, context: str) -> int:
    if isinstance(value, bool) or not isinstance(value, int):
        raise ValidatorError(f"{field_name} must be an integer in {context}")
    return value


def _require_list(value: object, *, field_name: str, context: str) -> list[object]:
    if not isinstance(value, list):
        raise ValidatorError(f"{field_name} must be a list in {context}")
    return value


def file_sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def _validate_port_lock_entry(
    entry: object,
    *,
    canonical_packages: list[str],
    library: str,
) -> dict[str, object]:
    if not isinstance(entry, dict):
        raise ValidatorError(f"port lock library entry for {library} must be an object")
    context = f"port lock library {library}"
    if entry.get("library") != library:
        raise ValidatorError(f"port lock library order mismatch: expected {library!r}")
    repository = _require_string(entry.get("repository"), field_name="repository", context=context)
    tag_ref = _require_string(entry.get("tag_ref"), field_name="tag_ref", context=context)
    commit = _require_string(entry.get("commit"), field_name="commit", context=context)
    release_tag = _require_string(entry.get("release_tag"), field_name="release_tag", context=context)
    if release_tag != f"build-{commit[:12]}":
        raise ValidatorError(f"port lock release_tag must equal build-<commit[:12]> in {context}")

    raw_debs = _require_list(entry.get("debs"), field_name="debs", context=context)
    if not raw_debs:
        raise ValidatorError(f"port lock library {library} must select at least one deb")
    raw_unported = _require_list(
        entry.get("unported_original_packages"),
        field_name="unported_original_packages",
        context=context,
    )
    unported: list[str] = []
    for package in raw_unported:
        unported.append(_require_string(package, field_name="unported package", context=context))

    debs_by_package: dict[str, dict[str, object]] = {}
    for raw_deb in raw_debs:
        if not isinstance(raw_deb, dict):
            raise ValidatorError(f"port lock deb entries for {library} must be objects")
        deb_context = f"port lock {library} deb"
        package = _require_string(raw_deb.get("package"), field_name="package", context=deb_context)
        filename = _require_string(raw_deb.get("filename"), field_name="filename", context=deb_context)
        architecture = _require_string(raw_deb.get("architecture"), field_name="architecture", context=deb_context)
        sha256 = _require_string(raw_deb.get("sha256"), field_name="sha256", context=deb_context)
        size = _require_int(raw_deb.get("size"), field_name="size", context=deb_context)
        if architecture not in {"amd64", "all"}:
            raise ValidatorError(f"port lock deb architecture must be amd64 or all for {library}/{package}")
        if package in debs_by_package:
            raise ValidatorError(f"port lock has duplicate deb package for {library}: {package}")
        if package not in canonical_packages:
            raise ValidatorError(f"port lock selects non-canonical package for {library}: {package}")
        if not filename.endswith(".deb"):
            raise ValidatorError(f"port lock deb filename must end with .deb for {library}/{package}")
        if len(sha256) != 64 or any(char not in "0123456789abcdef" for char in sha256):
            raise ValidatorError(f"port lock deb sha256 must be lowercase hex for {library}/{package}")
        if size < 0:
            raise ValidatorError(f"port lock deb size must be non-negative for {library}/{package}")
        debs_by_package[package] = {
            "package": package,
            "filename": filename,
            "architecture": architecture,
            "sha256": sha256,
            "size": size,
        }

    ported_packages = list(debs_by_package)
    if set(ported_packages).intersection(unported):
        raise ValidatorError(f"port lock debs and unported packages overlap for {library}")
    combined = [
        package
        for package in canonical_packages
        if package in debs_by_package or package in unported
    ]
    if combined != canonical_packages:
        raise ValidatorError(
            f"port lock debs plus unported_original_packages must equal canonical apt packages for {library}"
        )

    ordered_debs = [debs_by_package[package] for package in canonical_packages if package in debs_by_package]
    ordered_unported = [package for package in canonical_packages if package in unported]
    return {
        "repository": repository,
        "tag_ref": tag_ref,
        "commit": commit,
        "release_tag": release_tag,
        "port_debs": ordered_debs,
        "unported_original_packages": ordered_unported,
    }


def load_port_deb_lock(
    lock_path: Path,
    *,
    selected_entries: list[dict[str, object]],
) -> dict[str, dict[str, object]]:
    lock = _load_json_object(lock_path, description="port deb lock")
    if lock.get("schema_version") != 1:
        raise ValidatorError("port deb lock schema_version must be 1")
    if lock.get("mode") != "port-04-test":
        raise ValidatorError("port deb lock mode must be port-04-test")
    raw_libraries = _require_list(lock.get("libraries"), field_name="libraries", context="port deb lock")
    lock_by_library: dict[str, object] = {}
    for entry in raw_libraries:
        if not isinstance(entry, dict):
            raise ValidatorError("port deb lock library entries must be objects")
        library = _require_string(entry.get("library"), field_name="library", context="port deb lock")
        if library in lock_by_library:
            raise ValidatorError(f"port deb lock contains duplicate library: {library}")
        lock_by_library[library] = entry

    validated: dict[str, dict[str, object]] = {}
    for selected in selected_entries:
        library = str(selected["name"])
        raw_entry = lock_by_library.get(library)
        if raw_entry is None:
            raise ValidatorError(f"port deb lock missing selected library: {library}")
        validated[library] = _validate_port_lock_entry(
            raw_entry,
            canonical_packages=list(selected["apt_packages"]),
            library=library,
        )
    return validated


def validate_port_override_files(
    *,
    override_deb_dir: Path,
    library: str,
    lock_metadata: dict[str, object],
) -> None:
    expected_debs = lock_metadata["port_debs"]
    assert isinstance(expected_debs, list)
    expected_by_filename = {
        str(deb["filename"]): deb
        for deb in expected_debs
        if isinstance(deb, dict)
    }
    actual_debs = sorted(path for path in override_deb_dir.glob("*.deb") if path.is_file())
    actual_names = {path.name for path in actual_debs}
    expected_names = set(expected_by_filename)
    missing = sorted(expected_names - actual_names)
    extra = sorted(actual_names - expected_names)
    if missing or extra:
        details: list[str] = []
        if missing:
            details.append(f"missing {', '.join(missing)}")
        if extra:
            details.append(f"extra {', '.join(extra)}")
        raise ValidatorError(f"override deb files for {library} do not match port lock: " + "; ".join(details))
    for path in actual_debs:
        deb = expected_by_filename[path.name]
        expected_size = int(deb["size"])
        expected_sha256 = str(deb["sha256"])
        if path.stat().st_size != expected_size:
            raise ValidatorError(f"override deb size mismatch for {library}/{path.name}")
        if file_sha256(path) != expected_sha256:
            raise ValidatorError(f"override deb sha256 mismatch for {library}/{path.name}")


def shared_root(repo_root: Path) -> Path:
    shared = repo_root / "tests" / "_shared"
    if not shared.is_dir():
        raise ValidatorError(f"missing shared test runtime scripts: {shared}")
    return shared


def prepare_build_context(
    repo_root: Path,
    tests_root: Path,
    library: str,
) -> tuple[Path, Path]:
    library = validate_library_name(library)
    library_root = tests_root / library
    if not library_root.is_dir():
        raise ValidatorError(f"missing library harness for {library}: {library_root}")

    dockerfile = library_root / "Dockerfile"
    if not dockerfile.is_file():
        raise ValidatorError(f"missing Dockerfile for {library}: {dockerfile}")

    tempdir = Path(tempfile.mkdtemp(prefix=f"validator-run-matrix-{library}-"))
    try:
        shutil.copytree(shared_root(repo_root), tempdir / "_shared")
        shutil.copytree(library_root, tempdir / library)
    except Exception:
        shutil.rmtree(tempdir, ignore_errors=True)
        raise
    return tempdir, tempdir / library / "Dockerfile"


def image_tag_for(library: str, *, variant: str = "shared") -> str:
    library = validate_library_name(library)
    suffix = f"{library}-{variant}"
    image_name = "".join(char if char.isalnum() else "-" for char in suffix).strip("-") or "library"
    return f"validator-{image_name}"


def ensure_library_image(
    *,
    repo_root: Path,
    tests_root: Path,
    library: str,
    state: LibraryState,
    log_path: Path,
    variant: str = "shared",
) -> str:
    if variant in state.image_tags:
        return state.image_tags[variant]
    if variant in state.image_errors:
        raise ValidatorError(state.image_errors[variant])

    context_root, dockerfile = prepare_build_context(repo_root, tests_root, library)
    tag = image_tag_for(library, variant=variant)
    command = [
        "docker",
        "build",
        "--tag",
        tag,
        "--file",
        str(dockerfile),
        str(context_root),
    ]
    log_replacements = {str(context_root): f"/tmp/validator-run-matrix-{library}"}
    try:
        outcome = run_logged(
            command,
            log_path=log_path,
            log_replacements=log_replacements,
        )
    finally:
        shutil.rmtree(context_root, ignore_errors=True)

    if outcome.exit_code != 0:
        state.image_errors[variant] = f"docker build failed for {library}"
        raise ValidatorError(state.image_errors[variant])

    log_path.write_text(
        normalize_log_text(f"$ {shell_join(command)}\ndocker build completed\n", log_replacements),
        encoding="utf-8",
    )
    state.image_tags[variant] = tag
    return tag


def cleanup_library_images(states: dict[str, LibraryState]) -> list[str]:
    errors: list[str] = []
    for library, state in states.items():
        for variant, image_tag in list(state.image_tags.items()):
            try:
                completed = subprocess.run(
                    ["docker", "image", "rm", "--force", image_tag],
                    check=False,
                    capture_output=True,
                    text=True,
                )
            except OSError as exc:
                errors.append(
                    f"failed to remove docker image for {library} ({image_tag}): "
                    f"{type(exc).__name__}: {exc}"
                )
                del state.image_tags[variant]
                continue
            details = "\n".join(
                part.strip() for part in (completed.stdout or "", completed.stderr or "") if part.strip()
            )
            if completed.returncode != 0 and "No such image" not in details:
                errors.append(
                    f"failed to remove docker image for {library} ({image_tag}): "
                    f"{details or f'exit {completed.returncode}'}"
                )
            del state.image_tags[variant]
    return errors


def _bash_script_args(command: list[str]) -> list[str]:
    args = list(command[1:])
    while args:
        arg = args[0]
        if arg == "--":
            return args[1:]
        if not arg.startswith("-") or arg == "-":
            return args
        args = args[1:]
    return args


def _testcase_command_for_run(testcase: Testcase, *, record_casts: bool) -> list[str]:
    command = list(testcase.command)
    if not record_casts or not command or os.path.basename(command[0]) != "bash":
        return command
    return [
        command[0],
        "-c",
        'PS4=$1; shift; set -x; source "$@"',
        "validator-xtrace",
        VALIDATOR_XTRACE_PREFIX,
        *_bash_script_args(command),
    ]


def _container_command(
    *,
    image_tag: str,
    library: str,
    testcase: Testcase,
    record_casts: bool,
    status_dir: Path,
    override_deb_dir: Path | None,
) -> list[str]:
    command = ["docker", "run", "--rm"]
    if record_casts:
        command.append("-t")
    command.extend(
        [
            "--mount",
            f"type=bind,src={status_dir.resolve()},dst=/validator/status",
        ]
    )
    if override_deb_dir is not None:
        command.extend(
            [
                "--mount",
                f"type=bind,src={override_deb_dir.resolve()},dst=/override-debs,readonly",
            ]
        )
    command.extend(
        [
            image_tag,
            "bash",
            "-lc",
            (
                "set -euo pipefail\n"
                "/validator/tests/_shared/install_override_debs.sh\n"
                "exec /validator/tests/_shared/run_library_tests.sh \"$@\""
            ),
            "validator-testcase",
            library,
            testcase.id,
            "--",
            *_testcase_command_for_run(testcase, record_casts=record_casts),
        ]
    )
    return command


def _result_payload(
    *,
    testcase_manifest: TestcaseManifest,
    testcase: Testcase,
    mode: str,
    status: str,
    started_at: str,
    finished_at: str,
    duration_seconds: float,
    result_path: Path,
    log_path: Path,
    cast_path: Path | None,
    artifact_root: Path,
    exit_code: int,
    override_debs_installed: bool,
    port_metadata: dict[str, object] | None = None,
    override_installed_packages: list[dict[str, str]] | None = None,
    error: str | None = None,
) -> dict[str, object]:
    payload: dict[str, object] = {
        "schema_version": 2,
        "library": testcase_manifest.library,
        "mode": mode,
        "testcase_id": testcase.id,
        "title": testcase.title,
        "description": testcase.description,
        "kind": testcase.kind,
        "client_application": testcase.client_application,
        "tags": list(testcase.tags),
        "requires": list(testcase.requires),
        "status": status,
        "started_at": started_at,
        "finished_at": finished_at,
        "duration_seconds": duration_seconds,
        "result_path": artifact_relative_path(result_path, artifact_root),
        "log_path": artifact_relative_path(log_path, artifact_root),
        "cast_path": artifact_relative_path(cast_path, artifact_root) if cast_path is not None else None,
        "exit_code": exit_code,
        "command": list(testcase.command),
        "apt_packages": list(testcase_manifest.apt_packages),
        "override_debs_installed": override_debs_installed,
    }
    if mode == "port-04-test":
        if port_metadata is None:
            raise ValidatorError("port metadata is required for port-04-test result payloads")
        payload.update(
            {
                "port_repository": port_metadata["repository"],
                "port_tag_ref": port_metadata["tag_ref"],
                "port_commit": port_metadata["commit"],
                "port_release_tag": port_metadata["release_tag"],
                "port_debs": port_metadata["port_debs"],
                "unported_original_packages": port_metadata["unported_original_packages"],
                "override_installed_packages": override_installed_packages or [],
            }
        )
    if error is not None:
        payload["error"] = error
    return payload


def write_unrun_result(
    *,
    testcase_manifest: TestcaseManifest,
    testcase: Testcase,
    artifact_root: Path,
    mode: str,
    port_metadata: dict[str, object] | None,
    error: str,
) -> dict[str, object]:
    result_path = mode_artifact_path(artifact_root, mode, "results", testcase_manifest.library, f"{testcase.id}.json")
    log_path = mode_artifact_path(artifact_root, mode, "logs", testcase_manifest.library, f"{testcase.id}.log")
    if log_path.exists():
        log_path.unlink()
    append_log(log_path, f"{error}\n")
    now = iso_utc_now()
    result = _result_payload(
        testcase_manifest=testcase_manifest,
        testcase=testcase,
        mode=mode,
        status="failed",
        started_at=now,
        finished_at=now,
        duration_seconds=0.0,
        result_path=result_path,
        log_path=log_path,
        cast_path=None,
        artifact_root=artifact_root,
        exit_code=1,
        override_debs_installed=False,
        port_metadata=port_metadata,
        override_installed_packages=[],
        error=error,
    )
    write_json(result_path, result)
    return result


def read_override_installed_packages(
    status_dir: Path,
    *,
    port_metadata: dict[str, object],
) -> list[dict[str, str]]:
    status_path = status_dir / "override-installed-packages.tsv"
    if not status_path.is_file():
        raise ValidatorError("override-installed marker exists but package status file is missing")
    raw_lines = [line for line in status_path.read_text(encoding="utf-8").splitlines() if line.strip()]
    records: list[dict[str, str]] = []
    for line_number, line in enumerate(raw_lines, start=1):
        parts = line.split("\t")
        if len(parts) != 4 or any(not part for part in parts):
            raise ValidatorError(f"invalid override-installed-packages.tsv line {line_number}")
        package, version, architecture, filename = parts
        records.append(
            {
                "package": package,
                "version": version,
                "architecture": architecture,
                "filename": filename,
            }
        )

    expected_debs = port_metadata["port_debs"]
    assert isinstance(expected_debs, list)
    expected_keys = [
        (str(deb["package"]), str(deb["filename"]), str(deb["architecture"]))
        for deb in expected_debs
        if isinstance(deb, dict)
    ]
    records_by_key: dict[tuple[str, str, str], dict[str, str]] = {}
    for record in records:
        key = (record["package"], record["filename"], record["architecture"])
        if key in records_by_key:
            raise ValidatorError(f"duplicate override install status for package {record['package']}")
        records_by_key[key] = record
    actual_keys = set(records_by_key)
    expected_key_set = set(expected_keys)
    if actual_keys != expected_key_set:
        missing = sorted(expected_key_set - actual_keys)
        extra = sorted(actual_keys - expected_key_set)
        details: list[str] = []
        if missing:
            details.append(f"missing {missing!r}")
        if extra:
            details.append(f"extra {extra!r}")
        raise ValidatorError("override install status does not match port lock: " + "; ".join(details))
    return [records_by_key[key] for key in expected_keys]


def run_testcase(
    *,
    testcase_manifest: TestcaseManifest,
    testcase: Testcase,
    image_tag: str,
    artifact_root: Path,
    mode: str,
    port_metadata: dict[str, object] | None,
    override_deb_dir: Path | None,
    record_casts: bool,
) -> dict[str, object]:
    library = testcase_manifest.library
    result_path = mode_artifact_path(artifact_root, mode, "results", library, f"{testcase.id}.json")
    log_path = mode_artifact_path(artifact_root, mode, "logs", library, f"{testcase.id}.log")
    cast_path = mode_artifact_path(artifact_root, mode, "casts", library, f"{testcase.id}.cast") if record_casts else None
    for path in (result_path, log_path, cast_path):
        if path is not None and path.exists():
            path.unlink()

    status_dir = Path(tempfile.mkdtemp(prefix=f"validator-status-{library}-{testcase.id}-"))
    started_at = iso_utc_now()
    outcome = RunOutcome(1)
    error: str | None = None
    override_installed_packages: list[dict[str, str]] = []
    try:
        command = _container_command(
            image_tag=image_tag,
            library=library,
            testcase=testcase,
            record_casts=record_casts,
            status_dir=status_dir,
            override_deb_dir=override_deb_dir,
        )
        outcome = run_logged(
            command,
            log_path=log_path,
            cast_path=cast_path,
            timeout_seconds=testcase.timeout_seconds,
            log_replacements={
                str(status_dir.resolve()): f"/tmp/validator-status-{library}-{testcase.id}",
            },
            deterministic_cast=record_casts,
        )
        if outcome.timed_out:
            error = f"testcase timed out after {testcase.timeout_seconds} seconds"
            append_log(log_path, f"{error}\n")
        elif outcome.exit_code != 0:
            error = f"testcase command exited with status {outcome.exit_code}"
    finally:
        override_debs_installed = (status_dir / "override-installed").is_file()
        if mode == "port-04-test":
            if not override_debs_installed:
                status_error = "port override debs were not installed"
                append_log(log_path, f"{status_error}\n")
                error = status_error if error is None else f"{error}; {status_error}"
                outcome = RunOutcome(1, timed_out=outcome.timed_out)
            else:
                assert port_metadata is not None
                try:
                    override_installed_packages = read_override_installed_packages(
                        status_dir,
                        port_metadata=port_metadata,
                    )
                except ValidatorError as exc:
                    status_error = str(exc)
                    append_log(log_path, f"{status_error}\n")
                    error = status_error if error is None else f"{error}; {status_error}"
                    outcome = RunOutcome(1, timed_out=outcome.timed_out)
        shutil.rmtree(status_dir, ignore_errors=True)

    finished_at = iso_utc_now()
    duration_seconds = DETERMINISTIC_DURATION_SECONDS
    status = "passed" if outcome.exit_code == 0 and not outcome.timed_out else "failed"
    result = _result_payload(
        testcase_manifest=testcase_manifest,
        testcase=testcase,
        mode=mode,
        status=status,
        started_at=started_at,
        finished_at=finished_at,
        duration_seconds=duration_seconds,
        result_path=result_path,
        log_path=log_path,
        cast_path=cast_path if cast_path is not None and cast_path.is_file() else None,
        artifact_root=artifact_root,
        exit_code=outcome.exit_code,
        override_debs_installed=override_debs_installed,
        port_metadata=port_metadata,
        override_installed_packages=override_installed_packages,
        error=error,
    )
    write_json(result_path, result)
    return result


def write_library_summary(
    *,
    artifact_root: Path,
    testcase_manifest: TestcaseManifest,
    mode: str,
    results: list[dict[str, object]],
) -> dict[str, object]:
    library = testcase_manifest.library
    summary_path = mode_artifact_path(artifact_root, mode, "results", library, "summary.json")
    summary = {
        "schema_version": 2,
        "library": library,
        "mode": mode,
        "cases": len(results),
        "source_cases": sum(1 for result in results if result.get("kind") == "source"),
        "usage_cases": sum(1 for result in results if result.get("kind") == "usage"),
        "passed": sum(1 for result in results if result.get("status") == "passed"),
        "failed": sum(1 for result in results if result.get("status") == "failed"),
        "casts": sum(1 for result in results if result.get("cast_path") is not None),
        "duration_seconds": round(
            sum(float(result.get("duration_seconds", 0.0)) for result in results),
            3,
        ),
    }
    write_json(summary_path, summary)
    return summary


def run_library_cases(
    *,
    repo_root: Path,
    tests_root: Path,
    artifact_root: Path,
    testcase_manifest: TestcaseManifest,
    mode: str,
    port_metadata: dict[str, object] | None,
    override_deb_dir: Path | None,
    record_casts: bool,
    state: LibraryState,
) -> list[dict[str, object]]:
    library = testcase_manifest.library
    build_log_path = mode_artifact_path(artifact_root, mode, "logs", library, "docker-build.log")
    results: list[dict[str, object]] = []
    try:
        image_tag = ensure_library_image(
            repo_root=repo_root,
            tests_root=tests_root,
            library=library,
            state=state,
            log_path=build_log_path,
        )
    except ValidatorError as exc:
        error = str(exc)
        for testcase in testcase_manifest.testcases:
            results.append(
                write_unrun_result(
                    testcase_manifest=testcase_manifest,
                    testcase=testcase,
                    artifact_root=artifact_root,
                    mode=mode,
                    port_metadata=port_metadata,
                    error=error,
                )
            )
        write_library_summary(
            artifact_root=artifact_root,
            testcase_manifest=testcase_manifest,
            mode=mode,
            results=results,
        )
        return results

    for testcase in testcase_manifest.testcases:
        results.append(
            run_testcase(
                testcase_manifest=testcase_manifest,
                testcase=testcase,
                image_tag=image_tag,
                artifact_root=artifact_root,
                mode=mode,
                port_metadata=port_metadata,
                override_deb_dir=override_deb_dir,
                record_casts=record_casts,
            )
        )
    write_library_summary(
        artifact_root=artifact_root,
        testcase_manifest=testcase_manifest,
        mode=mode,
        results=results,
    )
    return results


def build_parser() -> argparse.ArgumentParser:
    repo_root = Path(__file__).resolve().parents[1]
    parser = argparse.ArgumentParser()
    parser.add_argument("--config", required=True, type=Path)
    parser.add_argument("--tests-root", type=Path, default=repo_root / "tests")
    parser.add_argument("--artifact-root", type=Path, default=repo_root / ".work" / "artifacts")
    parser.add_argument("--override-deb-root", type=Path)
    parser.add_argument("--port-deb-lock", type=Path)
    parser.add_argument("--mode", default="original")
    parser.add_argument("--record-casts", action="store_true")
    parser.add_argument("--library", action="append")
    parser.add_argument("--list-libraries", action="store_true")
    return parser


def parse_args(argv: list[str] | None = None) -> MatrixArgs:
    namespace = build_parser().parse_args(argv)
    mode = str(namespace.mode)
    if mode not in VALID_MODES:
        raise ValidatorError("--mode accepts only 'original' or 'port-04-test'")
    if mode == "port-04-test" and namespace.override_deb_root is None:
        raise ValidatorError("--override-deb-root is required for --mode port-04-test")
    if mode == "port-04-test" and namespace.port_deb_lock is None:
        raise ValidatorError("--port-deb-lock is required for --mode port-04-test")
    return MatrixArgs(
        config=namespace.config,
        tests_root=namespace.tests_root,
        artifact_root=namespace.artifact_root,
        override_deb_root=namespace.override_deb_root,
        port_deb_lock=namespace.port_deb_lock,
        mode=mode,
        record_casts=namespace.record_casts,
        library=namespace.library or None,
        list_libraries=namespace.list_libraries,
    )


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    manifest = load_manifest(args.config)
    selected = select_libraries(manifest, args.library)
    libraries = [validate_library_name(str(entry["name"])) for entry in selected]

    if args.list_libraries:
        for library in libraries:
            print(library)
        return 0

    selected_manifest = dict(manifest)
    selected_manifest["libraries"] = selected
    testcase_manifests = load_manifests(selected_manifest, tests_root=args.tests_root)

    port_lock: dict[str, dict[str, object]] = {}
    if args.mode == "port-04-test":
        assert args.port_deb_lock is not None
        port_lock = load_port_deb_lock(args.port_deb_lock, selected_entries=selected)

    override_deb_dirs: dict[str, Path | None] = {library: None for library in libraries}
    if args.override_deb_root is not None:
        validate_matrix_override_deb_root(args.override_deb_root)
        override_deb_dirs = {
            library: resolve_override_deb_dir(args.override_deb_root, library)
            for library in libraries
        }
        if args.mode == "port-04-test":
            for library in libraries:
                assert override_deb_dirs[library] is not None
                validate_port_override_files(
                    override_deb_dir=override_deb_dirs[library],
                    library=library,
                    lock_metadata=port_lock[library],
                )

    repo_root = Path(__file__).resolve().parents[1]
    args.artifact_root.mkdir(parents=True, exist_ok=True)
    states = {library: LibraryState() for library in libraries}
    any_failed = False
    try:
        for library in libraries:
            results = run_library_cases(
                repo_root=repo_root,
                tests_root=args.tests_root,
                artifact_root=args.artifact_root,
                testcase_manifest=testcase_manifests[library],
                mode=args.mode,
                port_metadata=port_lock.get(library),
                override_deb_dir=override_deb_dirs[library],
                record_casts=args.record_casts,
                state=states[library],
            )
            if any(result.get("status") != "passed" for result in results):
                any_failed = True
    finally:
        cleanup_errors = cleanup_library_images(states)
        if cleanup_errors and sys.exc_info()[1] is None:
            raise ValidatorError("\n".join(cleanup_errors))
        if cleanup_errors:
            print("\n".join(cleanup_errors), file=sys.stderr)

    return 1 if any_failed else 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except ValidatorError as exc:
        print(str(exc), file=sys.stderr)
        raise SystemExit(1)
