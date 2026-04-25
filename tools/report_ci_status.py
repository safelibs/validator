from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any

if __package__ in {None, ""}:
    sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from tools import ValidatorError


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser()
    parser.add_argument("--original-matrix-exit", required=True, type=int)
    parser.add_argument("--port-matrix-exit", required=True, type=int)
    parser.add_argument("--original-proof-path", required=True, type=Path)
    parser.add_argument("--port-proof-path", required=True, type=Path)
    return parser


def _load_proof(path: Path, *, expected_mode: str) -> dict[str, Any]:
    try:
        payload = json.loads(path.read_text())
    except FileNotFoundError as exc:
        raise ValidatorError(f"missing proof JSON: {path}") from exc
    except ValueError as exc:
        raise ValidatorError(f"invalid proof JSON at {path}: {exc}") from exc
    if not isinstance(payload, dict):
        raise ValidatorError(f"proof JSON must be an object at {path}")
    mode = payload.get("mode")
    if mode != expected_mode:
        raise ValidatorError(f"proof mode must be {expected_mode!r} at {path}")
    totals = payload.get("totals")
    if not isinstance(totals, dict):
        raise ValidatorError(f"proof totals must be an object at {path}")
    failed = totals.get("failed")
    if isinstance(failed, bool) or not isinstance(failed, int) or failed < 0:
        raise ValidatorError(f"proof totals.failed must be a non-negative integer at {path}")
    return payload


def _failed_count(path: Path, *, expected_mode: str) -> int:
    payload = _load_proof(path, expected_mode=expected_mode)
    totals = payload["totals"]
    assert isinstance(totals, dict)
    failed = totals["failed"]
    assert isinstance(failed, int)
    return failed


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    if args.original_matrix_exit != 0:
        print(f"original matrix failed with exit code {args.original_matrix_exit}", file=sys.stderr)
        return args.original_matrix_exit
    if args.port_matrix_exit != 0:
        print(f"port matrix failed with exit code {args.port_matrix_exit}", file=sys.stderr)
        return args.port_matrix_exit

    original_failed = _failed_count(args.original_proof_path, expected_mode="original")
    port_failed = _failed_count(args.port_proof_path, expected_mode="port-04-test")

    print(f"original proof failed cases: {original_failed}")
    print(f"port proof failed cases: {port_failed} (non-blocking)")

    if original_failed != 0:
        print("original proof must have zero failed cases", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except ValidatorError as exc:
        print(str(exc), file=sys.stderr)
        raise SystemExit(1)
