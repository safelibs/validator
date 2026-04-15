from __future__ import annotations

import argparse
import filecmp
import sys
from pathlib import Path
from typing import Any

if __package__ in {None, ""}:
    sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from tools import ValidatorError, list_relative_files, select_repositories
from tools.import_port_assets import resolve_import_sources
from tools.inventory import load_manifest


def compare_file(source: Path, dest: Path, description: str) -> None:
    if not source.exists():
        raise ValidatorError(f"missing source file for {description}: {source}")
    if not dest.exists():
        raise ValidatorError(f"missing imported file for {description}: {dest}")
    if source.is_symlink() != dest.is_symlink():
        raise ValidatorError(f"file identity drift detected for {description}: {dest}")
    if source.is_symlink():
        if source.readlink() != dest.readlink():
            raise ValidatorError(f"file identity drift detected for {description}: {dest}")
        return
    if not filecmp.cmp(source, dest, shallow=False):
        raise ValidatorError(f"content drift detected for {description}: {dest}")


def verify_library_assets(
    manifest: dict[str, Any],
    *,
    library: str,
    port_root: Path,
    workspace: Path,
    tests_root: Path,
) -> None:
    entry = select_repositories(manifest, [library])[0]
    stage_repo = port_root / library
    if not stage_repo.exists():
        raise ValidatorError(f"missing staged checkout for {library}: {stage_repo}")

    imported_root = tests_root / library / "tests"
    fixtures_root = imported_root / "fixtures"
    harness_root = imported_root / "harness-source"
    tagged_root = imported_root / "tagged-port"

    expected_fixtures = {
        "dependents.json": stage_repo / "dependents.json",
        "relevant_cves.json": stage_repo / "relevant_cves.json",
    }
    actual_fixtures = list_relative_files(fixtures_root)
    if actual_fixtures != set(expected_fixtures):
        raise ValidatorError(f"{library} fixtures mismatch: {sorted(actual_fixtures)}")
    for relative_path, source_path in expected_fixtures.items():
        compare_file(source_path, fixtures_root / relative_path, f"{library} fixtures/{relative_path}")

    expected_harness = {
        "original-test-script.sh": stage_repo / "test-original.sh",
        "debian/control": stage_repo / "safe" / "debian" / "control",
    }
    actual_harness = list_relative_files(harness_root)
    if actual_harness != set(expected_harness):
        raise ValidatorError(f"{library} harness-source mismatch: {sorted(actual_harness)}")
    for relative_path, source_path in expected_harness.items():
        compare_file(source_path, harness_root / relative_path, f"{library} harness/{relative_path}")

    expected_sources = resolve_import_sources(
        stage_repo,
        list(entry["validator"]["imports"]),
        library=library,
        workspace=workspace,
    )
    expected_tagged = {relative_path for relative_path, _ in expected_sources}
    actual_tagged = list_relative_files(tagged_root)
    if actual_tagged != expected_tagged:
        raise ValidatorError(f"{library} tagged-port mismatch: {sorted(actual_tagged)}")
    for relative_path, source_path in expected_sources:
        compare_file(
            source_path,
            tagged_root / relative_path,
            f"{library} tagged-port/{relative_path}",
        )


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser()
    parser.add_argument("--config", required=True, type=Path)
    parser.add_argument("--port-root", required=True, type=Path)
    parser.add_argument("--tests-root", type=Path, default=Path("tests"))
    parser.add_argument("--libraries", nargs="*")
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    manifest = load_manifest(args.config)
    workspace = args.port_root.parent
    for entry in select_repositories(manifest, args.libraries):
        verify_library_assets(
            manifest,
            library=str(entry["name"]),
            port_root=args.port_root,
            workspace=workspace,
            tests_root=args.tests_root,
        )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except ValidatorError as exc:
        print(str(exc), file=sys.stderr)
        raise SystemExit(1)
