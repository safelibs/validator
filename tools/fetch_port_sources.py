"""Fetch each port's safe/ source tree at the same commit as its debs.

Reads the port-deb lock file produced by ``fetch_port_debs.py`` to know
which commit per library backs the debs we're testing. For each library
it downloads a GitHub tarball at that commit, extracts only the ``safe/``
subtree, and writes it to ``output_root/port-{lib}/safe/...`` so
``tools.unsafe_blocks.count_library`` can walk it.

This is the bridge that lets CI populate per-library and aggregate
unsafe_blocks counts in the proof JSON without checking out the full
ports tree.
"""

from __future__ import annotations

import argparse
import io
import json
import shutil
import sys
import tarfile
import urllib.error
import urllib.request
from pathlib import Path
from typing import Any

if __package__ in {None, ""}:
    sys.dont_write_bytecode = True
    sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from tools import ValidatorError
from tools.fetch_port_debs import COMMIT_RE, github_headers


def _require_string(value: Any, *, field_name: str, context: str) -> str:
    if not isinstance(value, str) or not value.strip():
        raise ValidatorError(f"{context} must define non-empty {field_name}")
    return value.strip()


def _require_commit(value: Any, *, library: str) -> str:
    text = _require_string(value, field_name="commit", context=f"port-deb lock library {library!r}")
    if COMMIT_RE.fullmatch(text) is None:
        raise ValidatorError(f"port-deb lock library {library!r} commit must be a 40-hex sha")
    return text


def load_lock_libraries(lock_path: Path) -> list[dict[str, Any]]:
    try:
        payload = json.loads(lock_path.read_text())
    except FileNotFoundError as exc:
        raise ValidatorError(f"missing port-deb lock: {lock_path}") from exc
    except ValueError as exc:
        raise ValidatorError(f"invalid port-deb lock JSON at {lock_path}: {exc}") from exc
    if not isinstance(payload, dict):
        raise ValidatorError(f"port-deb lock must be a JSON object: {lock_path}")
    libraries = payload.get("libraries")
    if not isinstance(libraries, list):
        raise ValidatorError(f"port-deb lock libraries must be a list: {lock_path}")
    normalized: list[dict[str, Any]] = []
    for index, entry in enumerate(libraries, start=1):
        if not isinstance(entry, dict):
            raise ValidatorError(f"port-deb lock library entry #{index} must be an object")
        normalized.append(entry)
    return normalized


def _tarball_url(repository: str, commit: str) -> str:
    return f"https://api.github.com/repos/{repository}/tarball/{commit}"


def _download_tarball(url: str) -> bytes:
    request = urllib.request.Request(
        url,
        headers=github_headers(accept="application/vnd.github+json"),
    )
    try:
        with urllib.request.urlopen(request) as response:
            return response.read()
    except urllib.error.HTTPError as exc:
        raise ValidatorError(f"GitHub tarball download failed for {url}: HTTP {exc.code}") from exc
    except urllib.error.URLError as exc:
        raise ValidatorError(f"GitHub tarball download failed for {url}: {exc.reason}") from exc


def _safe_relative_path(member_name: str) -> str | None:
    parts = member_name.split("/", 2)
    if len(parts) < 3 or parts[1] != "safe":
        return None
    relative = parts[2]
    if not relative:
        return None
    for component in Path(relative).parts:
        if component in {"", "..", "."}:
            raise ValidatorError(f"refusing to extract suspicious tarball entry: {member_name}")
    return relative


def _extract_safe_subtree(tarball_bytes: bytes, *, target: Path) -> int:
    if target.exists():
        shutil.rmtree(target)
    target.mkdir(parents=True)
    extracted = 0
    with tarfile.open(fileobj=io.BytesIO(tarball_bytes), mode="r:gz") as tar:
        for member in tar.getmembers():
            relative = _safe_relative_path(member.name)
            if relative is None:
                continue
            destination = target / relative
            if member.isdir():
                destination.mkdir(parents=True, exist_ok=True)
                continue
            if not member.isfile():
                continue
            destination.parent.mkdir(parents=True, exist_ok=True)
            extracted_handle = tar.extractfile(member)
            if extracted_handle is None:
                continue
            with extracted_handle as src, destination.open("wb") as dst:
                shutil.copyfileobj(src, dst)
            extracted += 1
    if extracted == 0:
        raise ValidatorError(f"tarball contained no safe/ entries for {target}")
    return extracted


def fetch_port_source(
    *,
    library: str,
    repository: str,
    commit: str,
    output_root: Path,
) -> int:
    target = output_root / f"port-{library}" / "safe"
    url = _tarball_url(repository, commit)
    tarball_bytes = _download_tarball(url)
    return _extract_safe_subtree(tarball_bytes, target=target)


def fetch_lock(
    *,
    lock_path: Path,
    output_root: Path,
    libraries: list[str] | None = None,
) -> dict[str, dict[str, Any]]:
    selected = set(libraries) if libraries else None
    output_root.mkdir(parents=True, exist_ok=True)
    fetched: dict[str, dict[str, Any]] = {}
    for entry in load_lock_libraries(lock_path):
        library = _require_string(entry.get("library"), field_name="library", context="port-deb lock entry")
        if selected is not None and library not in selected:
            continue
        if entry.get("port_unavailable_reason"):
            continue
        repository = _require_string(
            entry.get("repository"),
            field_name="repository",
            context=f"port-deb lock library {library!r}",
        )
        commit = _require_commit(entry.get("commit"), library=library)
        files = fetch_port_source(
            library=library,
            repository=repository,
            commit=commit,
            output_root=output_root,
        )
        fetched[library] = {
            "library": library,
            "repository": repository,
            "commit": commit,
            "files_extracted": files,
        }
    return fetched


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser()
    parser.add_argument("--port-deb-lock", required=True, type=Path)
    parser.add_argument("--output-root", required=True, type=Path)
    parser.add_argument("--library", action="append")
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    output_root = args.output_root.resolve()
    lock_path = args.port_deb_lock.resolve()
    fetched = fetch_lock(
        lock_path=lock_path,
        output_root=output_root,
        libraries=args.library or None,
    )
    for library in sorted(fetched):
        info = fetched[library]
        print(f"{library:16s} commit={info['commit'][:12]} files={info['files_extracted']}")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except ValidatorError as exc:
        print(str(exc), file=sys.stderr)
        raise SystemExit(1)
