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
    parser.add_argument("--artifact-root", required=True, type=Path)
    parser.add_argument("--proof-output", required=True, type=Path)
    parser.add_argument("--library", action="append")
    parser.add_argument("--exclude-library", action="append", default=[])
    parser.add_argument("--exclude-note")
    parser.add_argument("--min-safe-workloads", type=int, default=0)
    parser.add_argument("--min-total-workloads", type=int, default=0)
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


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    if args.min_safe_workloads < 0 or args.min_total_workloads < 0:
        raise ValidatorError("workload thresholds must be non-negative")

    libraries = args.library or None
    if libraries is not None:
        _reject_duplicates(libraries, field_name="--library")
    _reject_duplicates(args.exclude_library, field_name="--exclude-library")

    artifact_root = args.artifact_root.resolve(strict=False)
    proof_output = args.proof_output.resolve(strict=False)
    try:
        proof_output.relative_to(artifact_root)
    except ValueError as exc:
        raise ValidatorError("--proof-output must resolve inside --artifact-root") from exc

    exclude_note = args.exclude_note or ""
    excluded_libraries = {
        library: exclude_note
        for library in args.exclude_library
    }
    manifest = load_manifest(args.config)
    proof = build_proof(
        manifest,
        artifact_root=artifact_root,
        libraries=libraries,
        excluded_libraries=excluded_libraries,
        min_safe_workloads=args.min_safe_workloads,
        min_total_workloads=args.min_total_workloads,
    )
    write_json(proof_output, proof)
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except ValidatorError as exc:
        print(str(exc), file=sys.stderr)
        raise SystemExit(1)
