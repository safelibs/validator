#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
STAGE="${1:-$ROOT/safe/target/stage}"
if [[ "$STAGE" != /* ]]; then
  STAGE="$ROOT/$STAGE"
fi

ARTIFACTS_ENV="$ROOT/safe/target/build-artifacts.env"
if [[ ! -f "$ARTIFACTS_ENV" ]]; then
  printf 'missing build metadata: %s\n' "$ARTIFACTS_ENV" >&2
  exit 1
fi

# shellcheck disable=SC1090
set -a
source "$ARTIFACTS_ENV"
set +a

python3 - "$ROOT" "$STAGE" <<'PY'
import os
import subprocess
import sys
import tomllib
from pathlib import Path

root = Path(sys.argv[1]).resolve()
stage = Path(sys.argv[2]).resolve()
manifest_path = root / "safe" / "build" / "modules.toml"
report_dir = root / "safe" / "target" / "audits"
report_dir.mkdir(parents=True, exist_ok=True)
report_path = report_dir / "residual-c-audit.txt"

manifest = tomllib.loads(manifest_path.read_text(encoding="utf-8"))
modules = [module for module in manifest["module"] if module.get("enabled", True)]
rust_modules = [module for module in modules if module["provider"] == "rust"]
residual_c = [module for module in modules if module["provider"] != "rust"]

triplet = os.environ.get("LIBXML2_TRIPLET") or subprocess.check_output(
    ["gcc", "-print-multiarch"], text=True
).strip()
stage_lib = stage / "usr" / "lib" / triplet / "libxml2.so.2"
stage_static = Path(os.environ["LIBXML2_NATIVE_STATIC"]).resolve()
support_archive = Path(os.environ["LIBXML2_SUPPORT_ARCHIVE"]).resolve()
module_audit = Path(os.environ.get("LIBXML2_MODULE_AUDIT", "")).resolve()

failures: list[str] = []
if not stage_lib.is_file():
    failures.append(f"missing staged shared library: {stage_lib}")
if not stage_static.is_file():
    failures.append(f"missing staged static archive: {stage_static}")
if module_audit and not module_audit.is_file():
    failures.append(f"missing module provenance report: {module_audit}")

core_original_sources = [
    module["source"] for module in modules if module["source"].startswith("../original/")
]
if core_original_sources:
    failures.append(
        "enabled modules still reference original C sources: "
        + ", ".join(sorted(core_original_sources))
    )

disallowed_residual = [
    f'{module["name"]}:{module["provider"]}:{module["source"]}'
    for module in residual_c
    if module["provider"] != "c_shim" or not module["source"].startswith("shims/")
]
if disallowed_residual:
    failures.append(
        "residual C modules are limited to safe/shims/*.c, found "
        + ", ".join(sorted(disallowed_residual))
    )

archive_members: list[str] = []
if stage_static.is_file():
    archive_members = subprocess.check_output(["ar", "t", str(stage_static)], text=True).splitlines()

support_members: list[str] = []
if support_archive.is_file():
    support_members = subprocess.check_output(["ar", "t", str(support_archive)], text=True).splitlines()

original_object_names = {f'{module["name"]}.o' for module in modules if module["source"].startswith("../original/")}
linked_original_members = sorted(original_object_names.intersection(archive_members))
if linked_original_members:
    failures.append(
        "libxml2.a still contains object members derived from original/*.c: "
        + ", ".join(linked_original_members)
    )

support_original_members = sorted(original_object_names.intersection(support_members))
if support_original_members:
    failures.append(
        "libxml2_c_support.a still contains object members derived from original/*.c: "
        + ", ".join(support_original_members)
    )

expected_residual_members = sorted(f'{module["name"]}.o' for module in residual_c)
missing_from_static = sorted(set(expected_residual_members).difference(archive_members))
missing_from_support = sorted(
    set(expected_residual_members).difference(support_members if support_members else [])
)
if missing_from_static:
    failures.append(
        "libxml2.a is missing residual C members: " + ", ".join(missing_from_static)
    )
if expected_residual_members and missing_from_support:
    failures.append(
        "libxml2_c_support.a is missing residual C members: " + ", ".join(missing_from_support)
    )

report_lines = [
    f"stage_shared={stage_lib}",
    f"stage_static={stage_static}",
    f"support_archive={support_archive}",
    f"module_audit={module_audit}",
    f"rust_module_count={len(rust_modules)}",
    f"residual_c_count={len(residual_c)}",
    "residual_c_modules:",
]
if residual_c:
    for module in residual_c:
        report_lines.append(f'  - {module["name"]}: {module["source"]}')
else:
    report_lines.append("  - none")
report_lines.extend(
    [
        "libxml2.a members checked:",
        *(f"  - {member}" for member in expected_residual_members),
    ]
)
report_path.write_text("\n".join(report_lines) + "\n", encoding="utf-8")

if failures:
    raise SystemExit("residual C audit failed:\n" + "\n".join(failures))

print(f"residual C audit passed: {len(rust_modules)} Rust core modules and {len(residual_c)} residual C shim modules")
print(f"audit report: {report_path}")
PY
