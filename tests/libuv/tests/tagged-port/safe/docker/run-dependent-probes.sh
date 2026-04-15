#!/usr/bin/env bash
set -euo pipefail

exec python3 - "$@" <<'PY'
import argparse
import json
import os
import shlex
import subprocess
import sys
import tempfile
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
    common_path = probes_root / "common.sh"

    if not manifest_path.is_file():
        fail(f"missing manifest: {manifest_path}")
    if not common_path.is_file():
        fail(f"missing common helper: {common_path}")

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

    entries = []
    seen_ids: set[str] = set()
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


def select_entries(entries: list[dict], requested_csv: str | None) -> list[dict]:
    by_id = {entry["id"]: entry for entry in entries}
    if not requested_csv:
        return entries

    requested: list[str] = []
    seen: set[str] = set()
    for raw_part in requested_csv.split(","):
        dependent_id = raw_part.strip()
        if not dependent_id:
            fail("dependent id list contains an empty item")
        if dependent_id in seen:
            fail(f"duplicate dependent id requested: {dependent_id}")
        if dependent_id not in by_id:
            fail(f"unknown dependent id requested: {dependent_id}")
        seen.add(dependent_id)
        requested.append(dependent_id)

    return [by_id[dependent_id] for dependent_id in requested]


def assert_target(common_sh: Path, kind: str, locator: str, env: dict[str, str]) -> None:
    command = (
        f". {shlex.quote(str(common_sh))}; "
        f"libuv_assert_expected_link_target {shlex.quote(kind)} {shlex.quote(locator)}"
    )
    subprocess.run(["bash", "-lc", command], check=True, env=env)


def main() -> int:
    parser = argparse.ArgumentParser(
        prog="run-dependent-probes.sh",
        description="Run checked-in dependent probes from a mounted probe tree."
    )
    parser.add_argument("--probes-root", required=True, help="Mounted safe/tests/dependents tree")
    parser.add_argument("--mode", required=True, choices=("smoke", "full"))
    parser.add_argument("--dependents", help="Comma-separated dependent IDs")
    parser.add_argument(
        "--assert-packaged-libuv",
        action="store_true",
        help="Assert that every declared link target resolves to the packaged libuv1t64"
    )
    parser.add_argument("--expected-libuv-path", help="Absolute libuv.so.1 path to assert instead of packaged libuv")
    parser.add_argument("--ld-library-path", help="LD_LIBRARY_PATH value to use for ldd resolution")
    args = parser.parse_args()

    if args.assert_packaged_libuv and args.expected_libuv_path:
        fail("cannot combine --assert-packaged-libuv with --expected-libuv-path")

    probes_root = Path(args.probes_root).resolve()
    if not probes_root.is_dir():
        fail(f"missing probes root: {probes_root}")

    entries = load_manifest(probes_root)
    selected_entries = select_entries(entries, args.dependents)
    common_sh = probes_root / "common.sh"

    base_env = os.environ.copy()
    base_env["LIBUV_DEPENDENT_MODE"] = args.mode
    if args.assert_packaged_libuv:
        base_env["LIBUV_EXPECTED_LIBUV_MODE"] = "package"
    elif args.expected_libuv_path:
        base_env["LIBUV_EXPECTED_LIBUV_MODE"] = "path"
        base_env["LIBUV_EXPECTED_LIBUV_PATH"] = args.expected_libuv_path
    if args.ld_library_path:
        base_env["LIBUV_LDD_LIBRARY_PATH"] = args.ld_library_path

    with tempfile.TemporaryDirectory(prefix="libuv-dependent-state-") as state_root_name:
        state_root = Path(state_root_name)
        for entry in selected_entries:
            probe_path = (probes_root / entry["probe_path"]).resolve()
            state_dir = state_root / entry["id"]
            state_dir.mkdir(parents=True, exist_ok=True)

            env = base_env.copy()
            env["LIBUV_DEPENDENT_ID"] = entry["id"]
            env["LIBUV_DEPENDENT_NAME"] = entry["software_name"]
            env["LIBUV_PROBE_STATE_DIR"] = str(state_dir)

            subprocess.run(["bash", str(probe_path)], check=True, cwd=probes_root, env=env)

            if "LIBUV_EXPECTED_LIBUV_MODE" in env:
                for target in entry["expected_link_targets"]:
                    assert_target(common_sh, target["kind"], target["locator"], env)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
PY
