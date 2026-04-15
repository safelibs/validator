#!/usr/bin/env bash
set -euo pipefail

source /validator/tests/_shared/runtime_helpers.sh

readonly tagged_root=${VALIDATOR_TAGGED_ROOT:?}
readonly library_tests_root="${VALIDATOR_LIBRARY_ROOT:?}/tests"
readonly work_root=$(mktemp -d)
readonly safe_root="$work_root/safe"
readonly copied_scripts_root="$tagged_root/safe/scripts"
readonly copied_include_root="$tagged_root/safe/include"
readonly copied_test_root="$tagged_root/safe/test"
readonly copied_regression_root="$tagged_root/safe/test-extra"
readonly copied_prebuilt_root="$tagged_root/safe/prebuilt"
readonly runtime_archive="$tagged_root/safe/prebuilt/x86_64-unknown-linux-gnu/libuv_safe_runtime_support.a"
readonly regression_manifest="$tagged_root/safe/test-extra/manifest.json"

cleanup() {
  rm -rf "$work_root"
}
trap cleanup EXIT

validator_require_file "$library_tests_root/fixtures/dependents.json"
validator_require_dir "$tagged_root/safe/docker"
validator_require_dir "$copied_scripts_root"
validator_require_dir "$copied_include_root"
validator_require_dir "$copied_test_root"
validator_require_dir "$copied_regression_root"
validator_require_dir "$copied_prebuilt_root"
validator_require_file "$tagged_root/safe/docker/dependents.Dockerfile"
validator_require_file "$tagged_root/safe/test/run-tests.c"
validator_require_file "$tagged_root/safe/test-extra/run-regressions.c"
validator_require_file "$runtime_archive"
validator_require_file "$regression_manifest"

validator_copy_tree "$tagged_root/safe/include" "$safe_root/include"
validator_copy_tree "$tagged_root/safe/test" "$safe_root/test"
validator_copy_tree "$tagged_root/safe/test-extra" "$safe_root/test-extra"

python3 - <<'PY' "$library_tests_root/fixtures/dependents.json"
from pathlib import Path
import json
import sys

expected = [
    "libnode109",
    "neovim",
    "bind9",
    "knot-resolver",
    "ttyd",
    "lua-luv",
    "libluv-ocaml",
    "python3-uvloop",
    "r-cran-fs",
    "r-cran-httpuv",
    "moarvm",
    "libh2o0.13t64",
    "libraft0",
    "libdqlite0",
    "libstorj0t64",
    "python3-gevent",
]
actual = [entry["binary_package"] for entry in json.loads(Path(sys.argv[1]).read_text())["dependents"]]
if actual != expected:
    raise SystemExit(f"unexpected libuv dependent matrix: {actual}")
PY

ar t "$runtime_archive" >/dev/null

cat >"$safe_root/test/test-list.h" <<'EOF'
TEST_DECLARE   (version)
TEST_DECLARE   (run_once)
TEST_DECLARE   (run_nowait)
TEST_DECLARE   (async)
TEST_DECLARE   (gethostname)
TEST_DECLARE   (tcp_ping_pong)
HELPER_DECLARE (tcp4_echo_server)

TASK_LIST_START
  TEST_ENTRY  (version)
  TEST_ENTRY  (run_once)
  TEST_ENTRY  (run_nowait)
  TEST_ENTRY  (async)
  TEST_ENTRY  (gethostname)
  TEST_ENTRY  (tcp_ping_pong)
  TEST_HELPER (tcp_ping_pong, tcp4_echo_server)
TASK_LIST_END
EOF

upstream_sources=(
  "$safe_root/test/test-getters-setters.c"
  "$safe_root/test/test-run-once.c"
  "$safe_root/test/test-run-nowait.c"
  "$safe_root/test/test-async.c"
  "$safe_root/test/test-gethostname.c"
  "$safe_root/test/test-ping-pong.c"
  "$safe_root/test/test-ipc.c"
  "$safe_root/test/test-ipc-heavy-traffic-deadlock-bug.c"
  "$safe_root/test/test-ipc-send-recv.c"
  "$safe_root/test/test-stdio-over-pipes.c"
  "$safe_root/test/test-spawn.c"
  "$safe_root/test/test-process-title.c"
)

cc \
  -std=c11 \
  -D_GNU_SOURCE \
  -Wall \
  -Wextra \
  -I"$safe_root/include" \
  -I"$safe_root/test" \
  "$safe_root/test/run-tests.c" \
  "$safe_root/test/runner.c" \
  "$safe_root/test/runner-unix.c" \
  "$safe_root/test/echo-server.c" \
  "$safe_root/test/blackhole-server.c" \
  "${upstream_sources[@]}" \
  "$runtime_archive" \
  $(pkg-config --cflags --libs libuv) \
  -ldl \
  -pthread \
  -lpthread \
  -lrt \
  -o "$work_root/run-tests"

for test_name in version run_once run_nowait async gethostname tcp_ping_pong; do
  UV_RUN_AS_ROOT=1 "$work_root/run-tests" "$test_name"
done

python3 - <<'PY' "$regression_manifest" | while IFS= read -r source_path; do
from pathlib import Path
import json
import sys

manifest = json.loads(Path(sys.argv[1]).read_text())
for entry in manifest["regressions"]:
    if entry["runner"] != "c":
        raise SystemExit(f"unsupported libuv regression runner: {entry['runner']}")
    print(entry["path"])
PY
  output_path="$work_root/$(basename "${source_path%.c}")"
  cc \
    -std=c11 \
    -D_GNU_SOURCE \
    -Wall \
    -Wextra \
    -I"$safe_root/include" \
    "$safe_root/test-extra/$source_path" \
    "$runtime_archive" \
    $(pkg-config --cflags --libs libuv) \
    -ldl \
    -pthread \
    -lpthread \
    -lrt \
    -o "$output_path"
  "$output_path"
done
