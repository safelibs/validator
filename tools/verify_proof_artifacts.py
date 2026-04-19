from __future__ import annotations

import argparse
import sys
from pathlib import Path

if __package__ in {None, ""}:
    sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from tools import ValidatorError, write_json
from tools.inventory import load_manifest
from tools.proof import build_proof


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser()
    parser.add_argument("--config", required=True, type=Path)
    parser.add_argument("--tests-root", type=Path, default=Path(__file__).resolve().parents[1] / "tests")
    parser.add_argument("--artifact-root", required=True, type=Path)
    parser.add_argument("--proof-output", required=True)
    parser.add_argument("--library", action="append")
    parser.add_argument("--exclude-library", action="append", default=[])
    parser.add_argument("--exclude-note")
    parser.add_argument("--record-casts", action="store_true")
    parser.add_argument("--require-casts", action="store_true")
    parser.add_argument("--min-total-cases", type=int, default=0)
    parser.add_argument("--min-source-cases", type=int, default=0)
    parser.add_argument("--min-usage-cases", type=int, default=0)
    return parser


def _reject_duplicates(values: list[str], *, field_name: str) -> None:
    seen: set[str] = set()
    duplicates: list[str] = []
    for value in values:
        if value in seen:
            duplicates.append(value)
        seen.add(value)
    if duplicates:
        raise ValidatorError(f"{field_name} must not contain duplicates: {', '.join(duplicates)}")


def _validate_proof_output_path(raw_path: str, *, artifact_root: Path) -> Path:
    if "\\" in raw_path:
        raise ValidatorError("--proof-output must not contain backslashes")
    proof_output = Path(raw_path)
    raw_parts = raw_path.split("/")
    if proof_output.is_absolute() and raw_parts and raw_parts[0] == "":
        raw_parts = raw_parts[1:]
    if any(part in {"", ".", ".."} for part in raw_parts):
        raise ValidatorError("--proof-output must not contain empty, '.', or '..' path segments")

    artifact_root_resolved = artifact_root.resolve(strict=False)
    proof_output_resolved = proof_output.resolve(strict=False) if proof_output.is_absolute() else (
        artifact_root / proof_output
    ).resolve(strict=False)
    try:
        proof_output_resolved.relative_to(artifact_root_resolved)
    except ValueError as exc:
        raise ValidatorError("--proof-output must resolve inside --artifact-root") from exc
    return proof_output_resolved


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    if args.min_total_cases < 0 or args.min_source_cases < 0 or args.min_usage_cases < 0:
        raise ValidatorError("case thresholds must be non-negative")

    libraries = args.library or None
    if libraries is not None:
        _reject_duplicates(libraries, field_name="--library")
    _reject_duplicates(args.exclude_library, field_name="--exclude-library")

    artifact_root = args.artifact_root.resolve(strict=False)
    proof_output = _validate_proof_output_path(args.proof_output, artifact_root=artifact_root)

    exclude_note = args.exclude_note or ""
    excluded_libraries = {
        library: exclude_note
        for library in args.exclude_library
    }
    manifest = load_manifest(args.config)
    proof = build_proof(
        manifest,
        artifact_root=artifact_root,
        tests_root=args.tests_root,
        libraries=libraries,
        excluded_libraries=excluded_libraries,
        record_casts_expected=args.record_casts or args.require_casts,
        min_total_cases=args.min_total_cases,
        min_source_cases=args.min_source_cases,
        min_usage_cases=args.min_usage_cases,
    )
    write_json(proof_output, proof)
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except ValidatorError as exc:
        print(str(exc), file=sys.stderr)
        raise SystemExit(1)
