from __future__ import annotations

import argparse
import sys
from pathlib import Path
from typing import Any

if __package__ in {None, ""}:
    sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from tools import (
    ValidatorError,
    copy_file,
    is_excluded_import_path,
    reset_dir,
    select_repositories,
    tracked_files,
)
from tools.inventory import load_manifest


def library_tests_root(dest_root: Path, library: str) -> Path:
    return dest_root / "tests" / library / "tests"


def _expand_mapped_import(
    repo_root: Path,
    tracked: list[str],
    tracked_set: set[str],
    *,
    source_path: str,
    dest_path: str,
) -> list[tuple[str, Path]]:
    repo_source = repo_root / source_path
    if repo_source.is_dir():
        source_prefix = f"{source_path.rstrip('/')}/"
        dest_prefix = f"{dest_path.rstrip('/')}/"
        return [
            (
                f"{dest_prefix}{candidate.removeprefix(source_prefix)}",
                repo_root / candidate,
            )
            for candidate in tracked
            if candidate.startswith(source_prefix) and not is_excluded_import_path(candidate)
        ]
    if source_path in tracked_set and not is_excluded_import_path(source_path):
        return [(dest_path.rstrip("/"), repo_root / source_path)]
    return []


def _expand_workspace_import(
    repo_root: Path,
    *,
    source_path: str,
    dest_path: str,
) -> list[tuple[str, Path]]:
    repo_source = repo_root / source_path
    if repo_source.is_dir():
        dest_prefix = dest_path.rstrip("/")
        return [
            (
                f"{dest_prefix}/{candidate.relative_to(repo_source).as_posix()}",
                candidate,
            )
            for candidate in sorted(repo_source.rglob("*"))
            if candidate.is_file()
            and not is_excluded_import_path(candidate.relative_to(repo_source).as_posix())
        ]
    if repo_source.is_file():
        return [(dest_path.rstrip("/"), repo_source)]
    return []


def _libuv_prebuilt_runtime_archive(workspace: Path) -> Path:
    return (
        workspace / "build-safe" / "libuv" / "source" / "safe" / "target" / "release" / "libuv.a"
    )


def _resolve_libuv_import_sources(
    repo_root: Path,
    tracked: list[str],
    tracked_set: set[str],
    *,
    import_path: str,
    workspace: Path,
) -> list[tuple[str, Path]]:
    if import_path == "safe/docker":
        mapped = _expand_mapped_import(
            repo_root,
            tracked,
            tracked_set,
            source_path="safe/docker",
            dest_path="safe/docker",
        )
        remapped: list[tuple[str, Path]] = []
        for dest_path, source_path_obj in mapped:
            if dest_path == "safe/docker/Dockerfile.dependents":
                remapped.append(("safe/docker/dependents.Dockerfile", source_path_obj))
            else:
                remapped.append((dest_path, source_path_obj))
        return remapped
    if import_path == "safe/scripts":
        return _expand_mapped_import(
            repo_root,
            tracked,
            tracked_set,
            source_path="safe/tools",
            dest_path="safe/scripts",
        )
    if import_path == "safe/test":
        return _expand_mapped_import(
            repo_root,
            tracked,
            tracked_set,
            source_path="safe/tests/upstream/test",
            dest_path="safe/test",
        )
    if import_path == "safe/test-extra":
        mapped = _expand_mapped_import(
            repo_root,
            tracked,
            tracked_set,
            source_path="safe/tests/regressions",
            dest_path="safe/test-extra",
        )
        mapped.extend(
            _expand_mapped_import(
                repo_root,
                tracked,
                tracked_set,
                source_path="safe/tests/harness/uv-safe-run-tests.c",
                dest_path="safe/test-extra/run-regressions.c",
            )
        )
        return mapped
    if import_path == "safe/prebuilt":
        runtime_archive = _libuv_prebuilt_runtime_archive(workspace)
        if not runtime_archive.is_file():
            raise ValidatorError(f"missing libuv prebuilt runtime support archive: {runtime_archive}")
        return [
            (
                "safe/prebuilt/x86_64-unknown-linux-gnu/libuv_safe_runtime_support.a",
                runtime_archive,
            )
        ]
    return []


def _resolve_libvips_import_sources(
    repo_root: Path,
    *,
    import_path: str,
) -> list[tuple[str, Path]]:
    if import_path == "build-check-install":
        return _expand_workspace_import(
            repo_root,
            source_path="build-check-install",
            dest_path="build-check-install",
        )
    return []


def resolve_import_sources(
    repo_root: Path,
    imports: list[str],
    *,
    library: str,
    workspace: Path,
) -> list[tuple[str, Path]]:
    tracked = tracked_files(repo_root)
    tracked_set = set(tracked)
    resolved: list[tuple[str, Path]] = []
    seen: set[str] = set()

    for raw_import in imports:
        import_path = raw_import.rstrip("/")
        matches: list[tuple[str, Path]] = []
        if library == "libuv":
            matches = _resolve_libuv_import_sources(
                repo_root,
                tracked,
                tracked_set,
                import_path=import_path,
                workspace=workspace,
            )
        elif library == "libvips":
            matches = _resolve_libvips_import_sources(
                repo_root,
                import_path=import_path,
            )
        if not matches:
            matches = _expand_mapped_import(
                repo_root,
                tracked,
                tracked_set,
                source_path=import_path,
                dest_path=import_path,
            )

        if not matches:
            raise ValidatorError(
                f"manifest import path has no tracked files in {repo_root}: {raw_import}"
            )

        for relative_path, source_path in sorted(matches, key=lambda item: item[0]):
            if relative_path not in seen:
                resolved.append((relative_path, source_path))
                seen.add(relative_path)
    return resolved


def import_library_assets(
    manifest: dict[str, Any],
    *,
    library: str,
    port_root: Path,
    workspace: Path,
    dest_root: Path,
) -> None:
    workspace.mkdir(parents=True, exist_ok=True)
    entry = select_repositories(manifest, [library])[0]
    stage_repo = port_root / library
    if not stage_repo.exists():
        raise ValidatorError(f"missing staged checkout for {library}: {stage_repo}")

    tests_root = library_tests_root(dest_root, library)
    tests_root.mkdir(parents=True, exist_ok=True)
    fixtures_root = tests_root / "fixtures"
    harness_root = tests_root / "harness-source"
    tagged_root = tests_root / "tagged-port"
    reset_dir(fixtures_root)
    reset_dir(harness_root)
    reset_dir(tagged_root)

    copy_file(stage_repo / "dependents.json", fixtures_root / "dependents.json")
    copy_file(
        stage_repo / "relevant_cves.json",
        fixtures_root / "relevant_cves.json",
    )
    copy_file(
        stage_repo / "test-original.sh",
        harness_root / "original-test-script.sh",
    )
    copy_file(
        stage_repo / "safe" / "debian" / "control",
        harness_root / "debian" / "control",
    )

    for relative_path, source_path in resolve_import_sources(
        stage_repo,
        list(entry["validator"]["imports"]),
        library=library,
        workspace=workspace,
    ):
        copy_file(source_path, tagged_root / relative_path)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser()
    parser.add_argument("--config", required=True, type=Path)
    parser.add_argument("--library", required=True)
    parser.add_argument("--port-root", required=True, type=Path)
    parser.add_argument("--workspace", required=True, type=Path)
    parser.add_argument("--dest-root", type=Path, default=Path("."))
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    manifest = load_manifest(args.config)
    import_library_assets(
        manifest,
        library=args.library,
        port_root=args.port_root,
        workspace=args.workspace,
        dest_root=args.dest_root,
    )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except ValidatorError as exc:
        print(str(exc), file=sys.stderr)
        raise SystemExit(1)
