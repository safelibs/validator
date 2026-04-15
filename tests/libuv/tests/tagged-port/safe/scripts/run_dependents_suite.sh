#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export LIBUV_SAFE_RUN_DEPENDENTS_SCRIPT_DIR="${script_dir}"

exec python3 - "$@" <<'PY'
import argparse
import json
import os
import subprocess
import sys
from pathlib import Path


EXPECTED_KEYS = {"id", "software_name", "coverage", "probe_path", "expected_link_targets"}
TARGET_KEYS = {"kind", "locator"}
ALLOWED_COVERAGE = {"runtime", "source-build"}
ALLOWED_KINDS = {"path", "python-module", "r-package", "probe-glob"}


def fail(message: str) -> "NoReturn":
    print(message, file=sys.stderr)
    raise SystemExit(1)


def load_manifest(probes_root: Path) -> list[dict]:
    manifest_path = probes_root / "manifest.json"
    if not manifest_path.is_file():
        fail(f"missing manifest: {manifest_path}")
    try:
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        fail(f"invalid manifest JSON: {exc}")

    if set(manifest) != {"schema_version", "dependents"}:
        fail("manifest must contain exactly schema_version and dependents")
    if manifest["schema_version"] != 1:
        fail("manifest schema_version must be 1")
    if not isinstance(manifest["dependents"], list):
        fail("manifest dependents must be a list")

    seen_ids: set[str] = set()
    entries = []
    for entry in manifest["dependents"]:
        if not isinstance(entry, dict):
            fail("each manifest dependent entry must be an object")
        if set(entry) != EXPECTED_KEYS:
            fail(f"manifest entry has unexpected keys: {entry}")
        dependent_id = entry["id"]
        if not isinstance(dependent_id, str) or not dependent_id:
            fail(f"invalid dependent id: {entry}")
        if dependent_id in seen_ids:
            fail(f"duplicate dependent id: {dependent_id}")
        seen_ids.add(dependent_id)

        coverage = entry["coverage"]
        if not isinstance(coverage, list) or not coverage or not all(isinstance(item, str) for item in coverage):
            fail(f"{dependent_id}: coverage must be a non-empty list of strings")
        if set(coverage) - ALLOWED_COVERAGE:
            fail(f"{dependent_id}: unsupported coverage values {coverage}")

        probe_path_value = entry["probe_path"]
        if not isinstance(probe_path_value, str) or not probe_path_value.endswith(".sh") or probe_path_value.startswith("/"):
            fail(f"{dependent_id}: invalid probe_path {probe_path_value}")
        probe_path = (probes_root / probe_path_value).resolve()
        try:
            probe_path.relative_to(probes_root.resolve())
        except ValueError:
            fail(f"{dependent_id}: probe_path escapes probes root: {probe_path_value}")
        if not probe_path.is_file():
            fail(f"{dependent_id}: missing probe file {probe_path}")

        targets = entry["expected_link_targets"]
        if not isinstance(targets, list) or not targets:
            fail(f"{dependent_id}: expected_link_targets must be a non-empty list")
        for target in targets:
            if not isinstance(target, dict) or set(target) != TARGET_KEYS:
                fail(f"{dependent_id}: invalid expected_link_target {target}")
            if target["kind"] not in ALLOWED_KINDS:
                fail(f"{dependent_id}: unsupported expected_link_target kind {target}")
            if not isinstance(target["locator"], str) or not target["locator"]:
                fail(f"{dependent_id}: invalid locator {target}")

        entries.append(entry)

    return entries


def select_ids(entries: list[dict], requested_csv: str | None) -> list[str]:
    ids_in_manifest = [entry["id"] for entry in entries]
    known = set(ids_in_manifest)
    if not requested_csv:
        return ids_in_manifest

    selected: list[str] = []
    seen: set[str] = set()
    for raw_part in requested_csv.split(","):
        dependent_id = raw_part.strip()
        if not dependent_id:
            fail("dependent id list contains an empty item")
        if dependent_id in seen:
            fail(f"duplicate dependent id requested: {dependent_id}")
        if dependent_id not in known:
            fail(f"unknown dependent id requested: {dependent_id}")
        seen.add(dependent_id)
        selected.append(dependent_id)
    return selected


def main() -> int:
    parser = argparse.ArgumentParser(
        prog="run_dependents_suite.sh",
        description="Run checked-in dependent probes inside a prepared dependents image."
    )
    parser.add_argument("--image", required=True, help="Docker image tag to run")
    parser.add_argument("--mode", required=True, choices=("smoke", "full"))
    parser.add_argument("--dependents", help="Comma-separated dependent IDs")
    parser.add_argument(
        "--assert-packaged-libuv",
        action="store_true",
        help="Assert that every declared link target resolves to the installed libuv1t64 package"
    )
    args = parser.parse_args()

    script_dir = Path(os.environ["LIBUV_SAFE_RUN_DEPENDENTS_SCRIPT_DIR"]).resolve()
    safe_root = script_dir.parent
    probes_root = (safe_root / "tests" / "dependents").resolve()
    entries = load_manifest(probes_root)
    selected_ids = select_ids(entries, args.dependents)

    command = [
        "docker",
        "run",
        "--rm",
        "-i",
        "--mount",
        f"type=bind,src={probes_root},target=/work/probes,readonly",
        args.image,
        "/usr/local/bin/run-dependent-probes.sh",
        "--probes-root",
        "/work/probes",
        "--mode",
        args.mode,
    ]
    if selected_ids:
        command.extend(["--dependents", ",".join(selected_ids)])
    if args.assert_packaged_libuv:
        command.append("--assert-packaged-libuv")

    subprocess.run(command, check=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
PY
