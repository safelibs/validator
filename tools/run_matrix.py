from __future__ import annotations

import argparse
import codecs
import errno
import fcntl
import json
import os
import pty
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
import uuid
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import TextIO

if __package__ in {None, ""}:
    sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from tools import ValidatorError, ensure_parent, select_libraries, write_json
from tools.inventory import load_manifest
from tools.testcases import Testcase, TestcaseManifest, load_manifests


CAST_COLUMNS = 120
CAST_ROWS = 40


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
    mode: str
    record_casts: bool
    library: list[str] | None
    list_libraries: bool


@dataclass(frozen=True)
class RunOutcome:
    exit_code: int
    timed_out: bool = False


def iso_utc_now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


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


def append_log(log_path: Path, text: str) -> None:
    ensure_parent(log_path)
    with log_path.open("a", encoding="utf-8") as handle:
        handle.write(text)


def shell_join(args: list[str]) -> str:
    return " ".join(shlex.quote(arg) for arg in args)


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
        log_handle.write(f"{type(exc).__name__}: {exc}\n")
        log_handle.flush()
        return RunOutcome(127)

    try:
        stdout, _ = process.communicate(timeout=timeout_seconds)
    except subprocess.TimeoutExpired as exc:
        timed_out_output = _text_from_timeout_output(exc.output)
        if timed_out_output:
            log_handle.write(timed_out_output)
        _kill_process_group(process)
        stdout, _ = process.communicate()
        if stdout:
            log_handle.write(stdout)
        log_handle.flush()
        return RunOutcome(124, timed_out=True)

    if stdout:
        log_handle.write(stdout)
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
) -> RunOutcome:
    ensure_parent(cast_path)
    with cast_path.open("w", encoding="utf-8") as cast_handle:
        cast_header = {
            "version": 2,
            "width": CAST_COLUMNS,
            "height": CAST_ROWS,
            "timestamp": int(time.time()),
            "env": {"TERM": "xterm-256color", "SHELL": "/bin/bash"},
        }
        cast_handle.write(json.dumps(cast_header) + "\n")

        master_fd, slave_fd = pty.openpty()
        set_pty_size(slave_fd, rows=CAST_ROWS, cols=CAST_COLUMNS)
        started = time.monotonic()
        deadline = started + float(timeout_seconds) if timeout_seconds is not None else None
        decoder = codecs.getincrementaldecoder("utf-8")("replace")
        timed_out = False

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
                log_handle.write(message)
                log_handle.flush()
                cast_handle.write(json.dumps([0.0, "o", message]) + "\n")
                return RunOutcome(127)
            finally:
                os.close(slave_fd)

            while True:
                now = time.monotonic()
                if deadline is not None and now >= deadline and process.poll() is None:
                    timed_out = True
                    timeout_message = f"\nprocess timed out after {timeout_seconds} seconds\n"
                    timestamp = round(now - started, 6)
                    log_handle.write(timeout_message)
                    cast_handle.write(json.dumps([timestamp, "o", timeout_message]) + "\n")
                    log_handle.flush()
                    cast_handle.flush()
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
                            timestamp = round(time.monotonic() - started, 6)
                            log_handle.write(text)
                            cast_handle.write(json.dumps([timestamp, "o", text]) + "\n")
                            log_handle.flush()
                            cast_handle.flush()
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
                            timestamp = round(time.monotonic() - started, 6)
                            log_handle.write(text)
                            cast_handle.write(json.dumps([timestamp, "o", text]) + "\n")
                    tail = decoder.decode(b"", final=True)
                    if tail:
                        timestamp = round(time.monotonic() - started, 6)
                        log_handle.write(tail)
                        cast_handle.write(json.dumps([timestamp, "o", tail]) + "\n")
                    log_handle.flush()
                    cast_handle.flush()
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
) -> RunOutcome:
    ensure_parent(log_path)
    with log_path.open("a", encoding="utf-8") as log_handle:
        log_handle.write(f"$ {shell_join(args)}\n")
        log_handle.flush()
        if cast_path is not None:
            return stream_process_with_cast(
                args,
                log_handle,
                cast_path,
                cwd=cwd,
                env=env,
                timeout_seconds=timeout_seconds,
            )
        return stream_process(
            args,
            log_handle,
            cwd=cwd,
            env=env,
            timeout_seconds=timeout_seconds,
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
    return f"validator-{image_name}-{uuid.uuid4().hex[:12]}"


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
    try:
        outcome = run_logged(
            [
                "docker",
                "build",
                "--tag",
                tag,
                "--file",
                str(dockerfile),
                str(context_root),
            ],
            log_path=log_path,
        )
    finally:
        shutil.rmtree(context_root, ignore_errors=True)

    if outcome.exit_code != 0:
        state.image_errors[variant] = f"docker build failed for {library}"
        raise ValidatorError(state.image_errors[variant])

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
            *testcase.command,
        ]
    )
    return command


def _result_payload(
    *,
    testcase_manifest: TestcaseManifest,
    testcase: Testcase,
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
    error: str | None = None,
) -> dict[str, object]:
    payload: dict[str, object] = {
        "schema_version": 2,
        "library": testcase_manifest.library,
        "mode": "original",
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
    if error is not None:
        payload["error"] = error
    return payload


def write_unrun_result(
    *,
    testcase_manifest: TestcaseManifest,
    testcase: Testcase,
    artifact_root: Path,
    error: str,
) -> dict[str, object]:
    result_path = artifact_path(artifact_root, "results", testcase_manifest.library, f"{testcase.id}.json")
    log_path = artifact_path(artifact_root, "logs", testcase_manifest.library, f"{testcase.id}.log")
    if log_path.exists():
        log_path.unlink()
    append_log(log_path, f"{error}\n")
    now = iso_utc_now()
    result = _result_payload(
        testcase_manifest=testcase_manifest,
        testcase=testcase,
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
        error=error,
    )
    write_json(result_path, result)
    return result


def run_testcase(
    *,
    testcase_manifest: TestcaseManifest,
    testcase: Testcase,
    image_tag: str,
    artifact_root: Path,
    override_deb_dir: Path | None,
    record_casts: bool,
) -> dict[str, object]:
    library = testcase_manifest.library
    result_path = artifact_path(artifact_root, "results", library, f"{testcase.id}.json")
    log_path = artifact_path(artifact_root, "logs", library, f"{testcase.id}.log")
    cast_path = artifact_path(artifact_root, "casts", library, f"{testcase.id}.cast") if record_casts else None
    for path in (result_path, log_path, cast_path):
        if path is not None and path.exists():
            path.unlink()

    status_dir = Path(tempfile.mkdtemp(prefix=f"validator-status-{library}-{testcase.id}-"))
    started_at = iso_utc_now()
    started = time.monotonic()
    outcome = RunOutcome(1)
    error: str | None = None
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
        )
        if outcome.timed_out:
            error = f"testcase timed out after {testcase.timeout_seconds} seconds"
            append_log(log_path, f"{error}\n")
        elif outcome.exit_code != 0:
            error = f"testcase command exited with status {outcome.exit_code}"
    finally:
        override_debs_installed = (status_dir / "override-installed").is_file()
        shutil.rmtree(status_dir, ignore_errors=True)

    finished_at = iso_utc_now()
    duration_seconds = round(time.monotonic() - started, 3)
    status = "passed" if outcome.exit_code == 0 and not outcome.timed_out else "failed"
    result = _result_payload(
        testcase_manifest=testcase_manifest,
        testcase=testcase,
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
        error=error,
    )
    write_json(result_path, result)
    return result


def write_library_summary(
    *,
    artifact_root: Path,
    testcase_manifest: TestcaseManifest,
    results: list[dict[str, object]],
) -> dict[str, object]:
    library = testcase_manifest.library
    summary_path = artifact_path(artifact_root, "results", library, "summary.json")
    summary = {
        "schema_version": 2,
        "library": library,
        "mode": "original",
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
    override_deb_dir: Path | None,
    record_casts: bool,
    state: LibraryState,
) -> list[dict[str, object]]:
    library = testcase_manifest.library
    build_log_path = artifact_path(artifact_root, "logs", library, "docker-build.log")
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
                    error=error,
                )
            )
        write_library_summary(
            artifact_root=artifact_root,
            testcase_manifest=testcase_manifest,
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
                override_deb_dir=override_deb_dir,
                record_casts=record_casts,
            )
        )
    write_library_summary(
        artifact_root=artifact_root,
        testcase_manifest=testcase_manifest,
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
    parser.add_argument("--mode", default="original")
    parser.add_argument("--record-casts", action="store_true")
    parser.add_argument("--library", action="append")
    parser.add_argument("--list-libraries", action="store_true")
    return parser


def parse_args(argv: list[str] | None = None) -> MatrixArgs:
    namespace = build_parser().parse_args(argv)
    mode = str(namespace.mode)
    if mode != "original":
        raise ValidatorError("--mode accepts only 'original' during the original-only runner phase")
    return MatrixArgs(
        config=namespace.config,
        tests_root=namespace.tests_root,
        artifact_root=namespace.artifact_root,
        override_deb_root=namespace.override_deb_root,
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

    override_deb_dirs: dict[str, Path | None] = {library: None for library in libraries}
    if args.override_deb_root is not None:
        validate_matrix_override_deb_root(args.override_deb_root)
        override_deb_dirs = {
            library: resolve_override_deb_dir(args.override_deb_root, library)
            for library in libraries
        }

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
