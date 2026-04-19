from __future__ import annotations

import atexit
import json
import os
import re
import shlex
import shutil
import subprocess
import sys
from fnmatch import fnmatch
from pathlib import Path, PurePosixPath
from typing import Any, Iterable

sys.dont_write_bytecode = True


def _cleanup_python_bytecode_caches() -> None:
    repo_root = Path(__file__).resolve().parents[1]
    for cache_dir in (Path(__file__).resolve().parent / "__pycache__", repo_root / "unit" / "__pycache__"):
        if cache_dir.exists():
            shutil.rmtree(cache_dir, ignore_errors=True)


atexit.register(_cleanup_python_bytecode_caches)


class ValidatorError(RuntimeError):
    """Raised when validator tooling fails."""


GLOBAL_IMPORT_IGNORED_DIRS = {
    ".git",
    ".libs",
    ".pc",
    "__pycache__",
    "build",
    "node_modules",
}
GLOBAL_IMPORT_IGNORED_DIR_PATTERNS = (
    ".checker-build*",
    "build-*",
)
GLOBAL_IMPORT_IGNORED_FILES = {
    "config.log",
    "config.status",
}
GLOBAL_IMPORT_IGNORED_FILE_PATTERNS = (
    "*.deb",
    "*.ddeb",
    "*.udeb",
)
AUTHENTICATED_GITHUB_URL_RE = re.compile(r"https://[^@\s/]+@github\.com/")


def redact_secrets(text: str, *, env: dict[str, str] | None = None) -> str:
    redacted = AUTHENTICATED_GITHUB_URL_RE.sub("https://REDACTED@github.com/", text)
    secrets: list[str] = []
    for source in (os.environ, env or {}):
        for name in ("GH_TOKEN", "VALIDATOR_REPO_TOKEN"):
            value = str(source.get(name, "")).strip()
            if value and value not in secrets:
                secrets.append(value)
    for secret in secrets:
        redacted = redacted.replace(secret, "REDACTED")
    return redacted


def run(
    args: list[str],
    *,
    cwd: Path | None = None,
    env: dict[str, str] | None = None,
    input_text: str | None = None,
    capture_output: bool = False,
) -> subprocess.CompletedProcess[str]:
    try:
        return subprocess.run(
            args,
            cwd=cwd,
            env=env,
            input=input_text,
            text=True,
            check=True,
            capture_output=capture_output,
        )
    except subprocess.CalledProcessError as exc:
        details = "\n".join(
            part.strip() for part in (exc.stdout or "", exc.stderr or "") if part.strip()
        )
        safe_args = [redact_secrets(arg, env=env) for arg in args]
        safe_details = redact_secrets(details or str(exc), env=env)
        location = f" (cwd={cwd})" if cwd is not None else ""
        raise ValidatorError(f"{' '.join(safe_args)} failed{location}: {safe_details}") from exc


def shell_quote(value: str) -> str:
    return shlex.quote(value)


def reset_dir(path: Path) -> None:
    if path.exists():
        shutil.rmtree(path)
    path.mkdir(parents=True, exist_ok=True)


def ensure_parent(path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)


def copy_file(source: Path, dest: Path) -> None:
    ensure_parent(dest)
    if dest.is_symlink() or dest.is_file():
        dest.unlink()
    if source.is_symlink():
        dest.symlink_to(source.readlink())
        return
    shutil.copy2(source, dest)


def write_json(path: Path, data: Any) -> None:
    ensure_parent(path)
    path.write_text(json.dumps(data, indent=2) + "\n")


def list_relative_files(root: Path) -> set[str]:
    if not root.exists():
        return set()
    return {
        path.relative_to(root).as_posix()
        for path in root.rglob("*")
        if path.is_file()
    }


def select_libraries(
    manifest: dict[str, Any],
    libraries: Iterable[str] | None = None,
) -> list[dict[str, Any]]:
    manifest_libraries = manifest["libraries"]
    if not isinstance(manifest_libraries, list):
        raise ValidatorError("manifest must define libraries")

    names: list[str] = []
    for index, entry in enumerate(manifest_libraries, start=1):
        if not isinstance(entry, dict) or not isinstance(entry.get("name"), str) or not entry["name"]:
            raise ValidatorError(f"manifest library #{index} must be a mapping with a name")
        names.append(str(entry["name"]))
    duplicate_manifest_names = sorted({name for name in names if names.count(name) > 1})
    if duplicate_manifest_names:
        raise ValidatorError(f"manifest library names must be unique: {', '.join(duplicate_manifest_names)}")

    if libraries is None:
        return list(manifest_libraries)

    selected_names: list[str] = []
    for library in libraries:
        if not isinstance(library, str) or not library:
            raise ValidatorError(f"library selections must be non-empty strings: {library!r}")
        selected_names.append(library)

    duplicate_selections = sorted({name for name in selected_names if selected_names.count(name) > 1})
    if duplicate_selections:
        raise ValidatorError(f"--library must not contain duplicates: {', '.join(duplicate_selections)}")

    unknown = [name for name in selected_names if name not in names]
    if unknown:
        raise ValidatorError(f"unknown libraries in config: {', '.join(unknown)}")

    selected_set = set(selected_names)
    return [entry for entry in manifest_libraries if str(entry["name"]) in selected_set]


def tracked_files(repo_root: Path) -> list[str]:
    output = run(
        ["git", "-C", str(repo_root), "ls-files", "-z"],
        capture_output=True,
    ).stdout
    return [path for path in output.split("\0") if path]


def is_ignored_import_path(relative_path: str) -> bool:
    path = PurePosixPath(relative_path)
    for part in path.parts[:-1]:
        if part in GLOBAL_IMPORT_IGNORED_DIRS:
            return True
        if any(fnmatch(part, pattern) for pattern in GLOBAL_IMPORT_IGNORED_DIR_PATTERNS):
            return True
    name = path.name
    if name in GLOBAL_IMPORT_IGNORED_FILES:
        return True
    return any(fnmatch(name, pattern) for pattern in GLOBAL_IMPORT_IGNORED_FILE_PATTERNS)


def expand_import_paths(repo_root: Path, imports: list[str]) -> list[str]:
    tracked = tracked_files(repo_root)
    tracked_set = set(tracked)
    expanded: list[str] = []
    seen: set[str] = set()

    for raw_import in imports:
        import_path = raw_import.rstrip("/")
        repo_path = repo_root / import_path
        matches: list[str] = []
        if repo_path.is_dir():
            prefix = f"{import_path}/"
            matches = [
                candidate
                for candidate in tracked
                if candidate.startswith(prefix) and not is_ignored_import_path(candidate)
            ]
        elif import_path in tracked_set and not is_ignored_import_path(import_path):
            matches = [import_path]

        if not matches:
            raise ValidatorError(
                f"manifest import path has no tracked files in {repo_root}: {raw_import}"
            )

        for match in sorted(matches):
            if match not in seen:
                expanded.append(match)
                seen.add(match)
    return expanded
