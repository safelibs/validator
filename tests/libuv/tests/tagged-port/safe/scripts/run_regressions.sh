#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export LIBUV_SAFE_REGRESSION_SCRIPT_DIR="${script_dir}"

exec python3 - "$@" <<'PY'
import argparse
import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path


IMPLEMENT_PHASE_ORDER = [
    "impl-01-baseline-and-artifact-policy",
    "impl-02-core-threading-parity",
    "impl-03-io-fs-resolver-parity",
    "impl-04-process-signal-security",
    "impl-05-full-upstream-and-relink",
    "impl-06-packaging-and-dependent-image",
    "impl-07-dependent-closure-and-release-hardening",
]
EXPECTED_KEYS = {
    "id",
    "path",
    "runner",
    "phase_owner",
    "compile_flags",
    "link_flags",
    "args",
}
ALLOWED_RUNNERS = {"c": "cc", "cpp": "c++", "shell": "bash"}
IGNORED_FILES = {"manifest.json", "README.md"}


def fail(message: str) -> "NoReturn":
    print(message, file=sys.stderr)
    raise SystemExit(1)


def stringify_list(entry: dict, key: str) -> list[str]:
    value = entry[key]
    if not isinstance(value, list) or not all(isinstance(item, str) for item in value):
        fail(f"{entry['id']}: {key} must be a list of strings")
    return value


def load_manifest(manifest_path: Path, regressions_root: Path, up_to_phase: str) -> list[dict]:
    if not manifest_path.is_file():
        fail(f"missing manifest: {manifest_path}")
    try:
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        fail(f"invalid manifest JSON: {exc}")

    if set(manifest) != {"schema_version", "regressions"}:
        fail("manifest must contain exactly schema_version and regressions")
    if manifest["schema_version"] != 1:
        fail("manifest schema_version must be 1")
    if not isinstance(manifest["regressions"], list):
        fail("manifest regressions must be a list")

    actual_files = {
        path.name
        for path in regressions_root.iterdir()
        if path.is_file() and path.name not in IGNORED_FILES
    }
    manifest_files = set()
    seen_ids = set()
    selected = []
    phase_cutoff = IMPLEMENT_PHASE_ORDER.index(up_to_phase)

    for entry in manifest["regressions"]:
        if not isinstance(entry, dict):
            fail("each manifest regression entry must be an object")
        if set(entry) != EXPECTED_KEYS:
            fail(f"manifest entry has unexpected keys: {entry}")
        if not isinstance(entry["id"], str) or not entry["id"]:
            fail(f"manifest entry has invalid id: {entry}")
        if entry["id"] in seen_ids:
            fail(f"duplicate regression id: {entry['id']}")
        seen_ids.add(entry["id"])

        path_value = entry["path"]
        if not isinstance(path_value, str) or not path_value or "/" in path_value:
            fail(f"{entry['id']}: path must be a slash-free file name")
        if entry["runner"] not in ALLOWED_RUNNERS:
            fail(f"{entry['id']}: unsupported runner {entry['runner']}")
        if entry["phase_owner"] not in IMPLEMENT_PHASE_ORDER:
            fail(f"{entry['id']}: unknown phase_owner {entry['phase_owner']}")

        stringify_list(entry, "compile_flags")
        stringify_list(entry, "link_flags")
        stringify_list(entry, "args")

        regression_path = regressions_root / path_value
        if not regression_path.is_file():
            fail(f"{entry['id']}: missing regression source {path_value}")

        manifest_files.add(path_value)
        if IMPLEMENT_PHASE_ORDER.index(entry["phase_owner"]) <= phase_cutoff:
            selected.append(entry)

    if manifest_files != actual_files:
        missing = sorted(actual_files - manifest_files)
        extra = sorted(manifest_files - actual_files)
        problems = []
        if missing:
            problems.append("unregistered files: " + ", ".join(missing))
        if extra:
            problems.append("missing files: " + ", ".join(extra))
        fail("manifest drift detected: " + "; ".join(problems))

    return selected


def main() -> int:
    parser = argparse.ArgumentParser(
        prog="run_regressions.sh",
        description="Compile and run checked-in regression probes up to a workflow phase."
    )
    parser.add_argument("--stage", required=True, help="Staged install prefix")
    parser.add_argument(
        "--up-to-phase",
        required=True,
        choices=IMPLEMENT_PHASE_ORDER,
        help="Highest implement phase whose regressions should run",
    )
    args = parser.parse_args()

    script_dir = Path(os.environ["LIBUV_SAFE_REGRESSION_SCRIPT_DIR"])
    safe_root = script_dir.parent
    regressions_root = safe_root / "tests" / "regressions"
    manifest_path = regressions_root / "manifest.json"
    stage_prefix = Path(args.stage).resolve()
    pc_path = stage_prefix / "lib" / "pkgconfig"

    if not stage_prefix.is_dir():
        fail(f"missing stage prefix: {stage_prefix}")
    if not pc_path.is_dir():
        fail(f"missing pkg-config directory: {pc_path}")

    selected = load_manifest(manifest_path, regressions_root, args.up_to_phase)
    if not selected:
        return 0

    env = os.environ.copy()
    env["PKG_CONFIG_PATH"] = str(pc_path)
    env["LIBUV_SAFE_STAGE"] = str(stage_prefix)
    ld_library_path = env.get("LD_LIBRARY_PATH")
    env["LD_LIBRARY_PATH"] = (
        f"{stage_prefix / 'lib'}:{ld_library_path}" if ld_library_path else str(stage_prefix / "lib")
    )

    with tempfile.TemporaryDirectory(prefix="libuv-safe-regressions-") as temp_dir_name:
        temp_dir = Path(temp_dir_name)
        pkg_flags = subprocess.check_output(
            ["pkg-config", "--cflags", "--libs", "libuv"],
            env=env,
            text=True,
        ).split()

        for entry in selected:
            runner = entry["runner"]
            source_path = regressions_root / entry["path"]
            if runner in {"c", "cpp"}:
                compiler = ALLOWED_RUNNERS[runner]
                binary_path = temp_dir / entry["id"]
                command = [
                    compiler,
                    str(source_path),
                    "-o",
                    str(binary_path),
                    *entry["compile_flags"],
                    *pkg_flags,
                    *entry["link_flags"],
                ]
                subprocess.run(command, check=True, cwd=regressions_root, env=env)
                subprocess.run(
                    [str(binary_path), *entry["args"]],
                    check=True,
                    cwd=regressions_root,
                    env=env,
                )
            elif runner == "shell":
                subprocess.run(
                    ["bash", str(source_path), *entry["args"]],
                    check=True,
                    cwd=regressions_root,
                    env=env,
                )
            else:
                fail(f"{entry['id']}: unsupported runner {runner}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
PY
