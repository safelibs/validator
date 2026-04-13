#!/usr/bin/env bash
set -euo pipefail

source /validator/tests/_shared/runtime_helpers.sh

readonly tagged_root=${VALIDATOR_TAGGED_ROOT:?}
readonly work_root=$(mktemp -d)
readonly shadow_root="$work_root/root"
readonly safe_root="$shadow_root/safe"
readonly original_root="$shadow_root/original"
readonly bin_root="$work_root/bin"
readonly noninteractive_manifest="$tagged_root/safe/generated/noninteractive_test_list.json"
readonly installed_tests_root="$tagged_root/safe/upstream-tests"

cleanup() {
  rm -rf "$work_root"
}
trap cleanup EXIT

validator_require_dir "$tagged_root/safe/tests"
validator_require_dir "$tagged_root/safe/debian/tests"
validator_require_dir "$tagged_root/safe/generated"
validator_require_dir "$tagged_root/safe/upstream-tests"
validator_require_dir "$tagged_root/original/test"

validator_copy_tree "$tagged_root/safe/tests" "$safe_root/tests"
validator_copy_tree "$tagged_root/safe/debian/tests" "$safe_root/debian/tests"
validator_copy_tree "$tagged_root/safe/generated" "$safe_root/generated"
validator_copy_tree "$tagged_root/safe/upstream-tests" "$safe_root/upstream-tests"
validator_copy_tree "$tagged_root/original/test" "$original_root/test"

mkdir -p "$bin_root"

(
  cd "$safe_root"
  sh debian/tests/build
  sh debian/tests/deprecated-use
  sh debian/tests/cmake
)

python3 - <<'PY' "$safe_root/generated/noninteractive_test_list.json" \
  "$safe_root/generated/original_test_port_map.json" \
  "$original_root/test"
from pathlib import Path
import json
import sys

manifest = json.loads(Path(sys.argv[1]).read_text())
port_map = json.loads(Path(sys.argv[2]).read_text())
original_root = Path(sys.argv[3])

targets = manifest["targets"]
entries = port_map["entries"]
known_targets = {
    target
    for entry in entries
    for target in entry.get("upstream_targets", [])
}

for target in targets:
    source = original_root / f"{target}.c"
    if not source.is_file():
        raise SystemExit(f"missing copied original test source: {source}")
    if target not in known_targets:
        raise SystemExit(f"target missing from copied original_test_port_map.json: {target}")
PY

compile_sdl() {
  local output=$1
  local source=$2
  shift 2
  cc \
    -std=c99 \
    -Wall \
    -Wextra \
    -I"$original_root/test" \
    "$source" \
    "$original_root/test/testutils.c" \
    $(pkg-config --cflags --libs sdl2) \
    "$@" \
    -o "$output"
}

compile_sdl "$bin_root/testver" "$original_root/test/testver.c"
compile_sdl "$bin_root/testqsort" "$original_root/test/testqsort.c" -lSDL2_test
compile_sdl "$bin_root/testfilesystem" "$original_root/test/testfilesystem.c"
compile_sdl "$bin_root/testplatform" "$original_root/test/testplatform.c"

"$bin_root/testver" >/dev/null
"$bin_root/testqsort" >/dev/null
"$bin_root/testfilesystem" >/dev/null
"$bin_root/testplatform" >/dev/null

autopkg_tmp="$work_root/autopkg"
mkdir -p "$autopkg_tmp/home" "$autopkg_tmp/runtime"
chmod 700 "$autopkg_tmp/runtime"

python3 - <<'PY' "$safe_root/generated/noninteractive_test_list.json" \
  "$safe_root/upstream-tests/installed-tests/usr/share/installed-tests/SDL2" >"$work_root/installed-tests.txt"
from pathlib import Path
import json
import sys

manifest = json.loads(Path(sys.argv[1]).read_text())
tests_root = Path(sys.argv[2])
for target in manifest["targets"]:
    test_file = tests_root / f"{target}.test"
    if not test_file.is_file():
        raise SystemExit(f"missing copied installed-test descriptor: {test_file}")
    for line in test_file.read_text().splitlines():
        if line.startswith("Exec="):
            print(line.split("=", 1)[1])
            break
    else:
        raise SystemExit(f"missing Exec= line in {test_file}")
PY

while IFS= read -r exec_path; do
  [[ -n "$exec_path" ]] || continue
  env \
    AUTOPKGTEST_TMP="$autopkg_tmp" \
    HOME="$autopkg_tmp/home" \
    XDG_RUNTIME_DIR="$autopkg_tmp/runtime" \
    SDL_AUDIODRIVER=dummy \
    SDL_VIDEODRIVER=dummy \
    "$exec_path" >/dev/null
done <"$work_root/installed-tests.txt"

python3 - <<'PY' "$safe_root/generated/dependent_regression_manifest.json" \
  "$safe_root/generated/perf_workload_manifest.json" \
  "$safe_root/generated/perf_thresholds.json" \
  "$safe_root/generated/reports/perf-baseline-vs-safe.json" \
  "$safe_root/generated/reports/perf-waivers.md"
from pathlib import Path
import json
import sys

dependent_manifest = json.loads(Path(sys.argv[1]).read_text())
perf_manifest = json.loads(Path(sys.argv[2]).read_text())
perf_thresholds = json.loads(Path(sys.argv[3]).read_text())
perf_report = json.loads(Path(sys.argv[4]).read_text())
waivers = Path(sys.argv[5]).read_text()

if dependent_manifest.get("schema_version") != 1:
    raise SystemExit("unexpected dependent regression schema")
if not isinstance(perf_manifest.get("workloads"), list) or not perf_manifest["workloads"]:
    raise SystemExit("perf workload manifest is empty")
if not isinstance(perf_thresholds.get("workloads"), list) or not perf_thresholds["workloads"]:
    raise SystemExit("perf threshold manifest is empty")
if not isinstance(perf_report.get("workloads"), list) or not perf_report["workloads"]:
    raise SystemExit("perf report is empty")
if "waiver" not in waivers.lower() and "No active waivers." not in waivers:
    raise SystemExit("unexpected perf waiver document")
PY
