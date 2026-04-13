from __future__ import annotations

import argparse
import codecs
import errno
import fcntl
import json
import os
import pty
import shlex
import shutil
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
from typing import Any, Iterable, TextIO

if __package__ in {None, ""}:
    sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from tools import ValidatorError, ensure_parent, select_repositories, write_json
from tools import build_safe_debs
from tools.inventory import load_manifest


MODE_ORDER = {"original": 0, "safe": 1}
CAST_COLUMNS = 120
CAST_ROWS = 40


@dataclass
class LibraryState:
    image_tags: dict[str, str] = field(default_factory=dict)
    image_errors: dict[str, str] = field(default_factory=dict)
    safe_deb_dir: Path | None = None
    safe_deb_error: str | None = None


@dataclass
class MatrixArgs:
    config: Path
    tests_root: Path
    port_root: Path | None
    artifact_root: Path
    safe_deb_root: Path | None
    mode: str
    record_casts: bool
    library: list[str] | None
    list_libraries: bool


def iso_utc_now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def dedupe(values: Iterable[str]) -> list[str]:
    return list(dict.fromkeys(values))


def ordered_modes(mode: str) -> list[str]:
    if mode == "both":
        return ["original", "safe"]
    return [mode]


def artifact_relative_path(path: Path, artifact_root: Path) -> str:
    return path.resolve(strict=False).relative_to(artifact_root.resolve(strict=False)).as_posix()


def validate_library_name(library: str) -> str:
    if not library or library in {".", ".."}:
        raise ValidatorError(f"unsafe library name: {library!r}")
    if Path(library).is_absolute() or "/" in library or "\\" in library:
        raise ValidatorError(f"unsafe library name: {library!r}")
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


def stream_process(args: list[str], log_handle: TextIO) -> int:
    try:
        process = subprocess.Popen(
            args,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            encoding="utf-8",
            errors="replace",
        )
    except OSError as exc:
        log_handle.write(f"{type(exc).__name__}: {exc}\n")
        log_handle.flush()
        return 127

    assert process.stdout is not None
    with process.stdout:
        for chunk in process.stdout:
            log_handle.write(chunk)
    return process.wait()


def stream_process_with_cast(args: list[str], log_handle: TextIO, cast_path: Path) -> int:
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
        decoder = codecs.getincrementaldecoder("utf-8")("replace")

        try:
            try:
                process = subprocess.Popen(args, stdin=slave_fd, stdout=slave_fd, stderr=slave_fd)
            except OSError as exc:
                log_handle.write(f"{type(exc).__name__}: {exc}\n")
                log_handle.flush()
                cast_handle.write(json.dumps([0.0, "o", f"{type(exc).__name__}: {exc}\n"]) + "\n")
                return 127
            finally:
                os.close(slave_fd)

            while True:
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
                    tail = decoder.decode(b"", final=True)
                    if tail:
                        timestamp = round(time.monotonic() - started, 6)
                        log_handle.write(tail)
                        cast_handle.write(json.dumps([timestamp, "o", tail]) + "\n")
                    log_handle.flush()
                    cast_handle.flush()
                    return process.wait()
        finally:
            os.close(master_fd)


def run_logged(
    args: list[str],
    *,
    log_path: Path,
    cast_path: Path | None = None,
) -> int:
    ensure_parent(log_path)
    with log_path.open("a", encoding="utf-8") as log_handle:
        log_handle.write(f"$ {shell_join(args)}\n")
        log_handle.flush()
        if cast_path is not None:
            return stream_process_with_cast(args, log_handle, cast_path)
        return stream_process(args, log_handle)


def validate_matrix_safe_deb_root(root: Path) -> None:
    if not root.exists():
        raise ValidatorError(f"safe-deb root does not exist: {root}")
    if not root.is_dir():
        raise ValidatorError(f"safe-deb root must be a directory: {root}")
    if list(root.glob("*.deb")):
        raise ValidatorError(
            "--safe-deb-root must point to a matrix root laid out as <safe-deb-root>/<library>/*.deb"
        )


def resolve_safe_deb_dir(root: Path, library: str) -> Path:
    library = validate_library_name(library)
    library_root = root / library
    if not library_root.is_dir():
        raise ValidatorError(
            f"missing safe-deb leaf for {library}: expected {root / library} with .deb files"
        )
    debs = sorted(library_root.glob("*.deb"))
    if not debs:
        raise ValidatorError(
            f"safe-deb leaf for {library} contains no .deb files: {library_root}"
        )
    return library_root


def shared_root(repo_root: Path) -> Path:
    shared = repo_root / "tests" / "_shared"
    if not shared.is_dir():
        raise ValidatorError(f"missing shared test runtime scripts: {shared}")
    return shared


def prepare_build_context(
    repo_root: Path,
    tests_root: Path,
    port_root: Path | None,
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
        if port_root is None:
            (tempdir / "port").mkdir()
        else:
            staged_port = port_root / library
            if not staged_port.is_dir():
                raise ValidatorError(f"missing staged port repo for {library}: {staged_port}")
            shutil.copytree(staged_port, tempdir / "port")
    except Exception:
        shutil.rmtree(tempdir, ignore_errors=True)
        raise
    return tempdir, tempdir / library / "Dockerfile"


def image_tag_for(library: str, *, variant: str) -> str:
    library = validate_library_name(library)
    suffix = f"{library}-{variant}"
    safe_name = "".join(char if char.isalnum() else "-" for char in suffix).strip("-") or "library"
    return f"validator-{safe_name}-{uuid.uuid4().hex[:12]}"


def ensure_library_image(
    *,
    repo_root: Path,
    tests_root: Path,
    port_root: Path | None,
    library: str,
    state: LibraryState,
    log_path: Path,
    variant: str = "shared",
    build_args: dict[str, str] | None = None,
) -> str:
    if variant in state.image_tags:
        return state.image_tags[variant]
    if variant in state.image_errors:
        raise ValidatorError(state.image_errors[variant])

    context_root, dockerfile = prepare_build_context(repo_root, tests_root, port_root, library)
    tag = image_tag_for(library, variant=variant)
    build_arg_items = sorted((build_args or {}).items())
    try:
        exit_code = run_logged(
            [
                "docker",
                "build",
                *[
                    option
                    for name, value in build_arg_items
                    for option in ("--build-arg", f"{name}={value}")
                ],
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

    if exit_code != 0:
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


def ensure_safe_deb_dir(
    *,
    manifest: dict[str, Any],
    library: str,
    port_root: Path | None,
    artifact_root: Path,
    safe_deb_root: Path | None,
    state: LibraryState,
    log_path: Path,
) -> Path:
    library = validate_library_name(library)
    if safe_deb_root is not None:
        return resolve_safe_deb_dir(safe_deb_root, library)

    if state.safe_deb_dir is not None:
        return state.safe_deb_dir
    if state.safe_deb_error is not None:
        raise ValidatorError(state.safe_deb_error)
    if port_root is None:
        raise ValidatorError("safe mode requires either --safe-deb-root or --port-root")

    output_dir = artifact_path(artifact_root, "debs", library)
    workspace = artifact_root / ".workspace"
    append_log(log_path, f"Building safe debs for {library} into {output_dir}\n")
    try:
        build_safe_debs.build_library(
            manifest,
            library=library,
            port_root=port_root,
            workspace=workspace,
            output=output_dir,
        )
    except ValidatorError as exc:
        state.safe_deb_error = str(exc)
        raise

    if not list(output_dir.glob("*.deb")):
        state.safe_deb_error = f"safe-deb build produced no .deb files for {library}: {output_dir}"
        raise ValidatorError(state.safe_deb_error)

    state.safe_deb_dir = output_dir
    return output_dir


def run_library_mode(
    *,
    manifest: dict[str, Any],
    repo_root: Path,
    tests_root: Path,
    artifact_root: Path,
    port_root: Path | None,
    safe_deb_root: Path | None,
    record_casts: bool,
    library: str,
    mode: str,
    state: LibraryState,
) -> dict[str, Any]:
    library = validate_library_name(library)
    log_path = artifact_path(artifact_root, "logs", library, f"{mode}.log")
    result_path = artifact_path(artifact_root, "results", library, f"{mode}.json")
    cast_candidate = artifact_path(artifact_root, "casts", library, "safe.cast")
    ensure_parent(result_path)
    ensure_parent(log_path)
    if log_path.exists():
        log_path.unlink()
    if cast_candidate.exists():
        cast_candidate.unlink()

    started_at = iso_utc_now()
    started = time.monotonic()
    exit_code = 0
    status = "passed"
    error_message: str | None = None

    try:
        image_variant = "shared"
        image_build_args: dict[str, str] = {}
        if library == "libxml":
            image_variant = mode
            image_build_args["VALIDATOR_TEST_MODE"] = mode
        image_tag = ensure_library_image(
            repo_root=repo_root,
            tests_root=tests_root,
            port_root=port_root,
            library=library,
            state=state,
            log_path=log_path,
            variant=image_variant,
            build_args=image_build_args,
        )

        command = ["docker", "run", "--rm"]
        cast_path: Path | None = None
        # Safe-mode runs must execute through bash -x so the captured cast shows the trace.
        trace_shell = "bash -x"
        if mode == "safe":
            safe_deb_dir = ensure_safe_deb_dir(
                manifest=manifest,
                library=library,
                port_root=port_root,
                artifact_root=artifact_root,
                safe_deb_root=safe_deb_root,
                state=state,
                log_path=log_path,
            )
            command.extend(
                [
                    "--mount",
                    f"type=bind,src={safe_deb_dir.resolve()},dst=/safedebs,readonly",
                ]
            )
            if record_casts:
                command.append("-t")
                cast_path = cast_candidate
        else:
            cast_path = None

        command.extend(
            [
                image_tag,
                "bash",
                "-x",
                f"/validator/tests/{library}/docker-entrypoint.sh",
            ]
        )

        exit_code = run_logged(command, log_path=log_path, cast_path=cast_path)
        if exit_code != 0:
            status = "failed"
    except ValidatorError as exc:
        status = "failed"
        error_message = str(exc)
        append_log(log_path, f"{error_message}\n")
    except Exception as exc:  # pragma: no cover - defensive fallback
        status = "failed"
        error_message = f"{type(exc).__name__}: {exc}"
        append_log(log_path, f"{error_message}\n")

    finished_at = iso_utc_now()
    duration_seconds = round(time.monotonic() - started, 3)
    cast_rel = (
        artifact_relative_path(cast_candidate, artifact_root)
        if mode == "safe" and record_casts and cast_candidate.is_file()
        else None
    )
    result = {
        "library": library,
        "mode": mode,
        "status": status,
        "started_at": started_at,
        "finished_at": finished_at,
        "duration_seconds": duration_seconds,
        "log_path": artifact_relative_path(log_path, artifact_root),
        "cast_path": cast_rel,
        "exit_code": exit_code,
    }
    if error_message is not None:
        result["error"] = error_message
    return result


def build_parser() -> argparse.ArgumentParser:
    repo_root = Path(__file__).resolve().parents[1]
    parser = argparse.ArgumentParser()
    parser.add_argument("--config", required=True, type=Path)
    parser.add_argument("--tests-root", type=Path, default=repo_root / "tests")
    parser.add_argument("--port-root", type=Path)
    parser.add_argument("--artifact-root", type=Path, default=repo_root / ".work" / "artifacts")
    parser.add_argument("--safe-deb-root", type=Path)
    parser.add_argument("--mode", choices=("original", "safe", "both"), default="both")
    parser.add_argument("--record-casts", action="store_true")
    parser.add_argument("--library", action="append")
    parser.add_argument("--list-libraries", action="store_true")
    return parser


def parse_args(argv: list[str] | None = None) -> MatrixArgs:
    namespace = build_parser().parse_args(argv)
    libraries = dedupe(namespace.library or [])
    return MatrixArgs(
        config=namespace.config,
        tests_root=namespace.tests_root,
        port_root=namespace.port_root,
        artifact_root=namespace.artifact_root,
        safe_deb_root=namespace.safe_deb_root,
        mode=namespace.mode,
        record_casts=namespace.record_casts,
        library=libraries or None,
        list_libraries=namespace.list_libraries,
    )


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    manifest = load_manifest(args.config)
    selected = select_repositories(manifest, args.library)
    libraries = [validate_library_name(str(entry["name"])) for entry in selected]

    if args.list_libraries:
        for library in libraries:
            print(library)
        return 0

    modes = ordered_modes(args.mode)
    if "safe" in modes and args.safe_deb_root is not None:
        validate_matrix_safe_deb_root(args.safe_deb_root)
    if "safe" in modes and args.safe_deb_root is None and args.port_root is None:
        raise ValidatorError("safe mode requires either --safe-deb-root or --port-root")

    repo_root = Path(__file__).resolve().parents[1]
    args.artifact_root.mkdir(parents=True, exist_ok=True)
    states = {library: LibraryState() for library in libraries}
    any_failed = False
    try:
        for library in libraries:
            for mode in modes:
                result = run_library_mode(
                    manifest=manifest,
                    repo_root=repo_root,
                    tests_root=args.tests_root,
                    artifact_root=args.artifact_root,
                    port_root=args.port_root,
                    safe_deb_root=args.safe_deb_root,
                    record_casts=args.record_casts,
                    library=library,
                    mode=mode,
                    state=states[library],
                )
                result_path = args.artifact_root / "results" / library / f"{mode}.json"
                write_json(result_path, result)
                if result["status"] != "passed":
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
