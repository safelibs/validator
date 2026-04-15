#!/usr/bin/env bash
set -euo pipefail

source /validator/tests/_shared/runtime_helpers.sh

readonly tagged_root=${VALIDATOR_TAGGED_ROOT:?}
readonly library_tests_root="${VALIDATOR_LIBRARY_ROOT:?}/tests"
readonly work_root=$(mktemp -d)
readonly safe_root="$work_root/safe"
readonly copied_scripts_root="$tagged_root/safe/scripts"
readonly copied_docker_root="$tagged_root/safe/docker"
readonly copied_dependents_root="$tagged_root/safe/tests/dependents"
readonly copied_extra_root="$tagged_root/safe/tests/extra"
readonly copied_upstream_root="$tagged_root/safe/tests/upstream"
readonly forbidden_generated_root="$tagged_root/safe/tests"/generated

cleanup() {
  rm -rf "$work_root"
}
trap cleanup EXIT

validator_require_file "$library_tests_root/fixtures/dependents.json"
validator_require_dir "$copied_docker_root"
validator_require_dir "$copied_scripts_root"
validator_require_dir "$copied_dependents_root"
validator_require_dir "$copied_extra_root"
validator_require_dir "$copied_upstream_root"
validator_require_file "$tagged_root/safe/docker/dependent-test.Dockerfile"
validator_require_file "$tagged_root/safe/scripts/run-dependent-matrix.sh"
validator_require_file "$tagged_root/safe/tests/dependents/boost_iostreams_smoke.cpp"
validator_require_file "$tagged_root/safe/tests/upstream/bcj_test.c"
if [[ -e "$forbidden_generated_root" ]]; then
  printf 'liblzma import drifted: generated tests directory must not be present\n' >&2
  exit 1
fi

validator_copy_tree "$tagged_root/safe/docker" "$safe_root/docker"
validator_copy_tree "$tagged_root/safe/scripts" "$safe_root/scripts"
validator_copy_tree "$tagged_root/safe/tests/dependents" "$safe_root/tests/dependents"
validator_copy_tree "$tagged_root/safe/tests/extra" "$safe_root/tests/extra"
validator_copy_tree "$tagged_root/safe/tests/upstream" "$safe_root/tests/upstream"

chmod +x \
  "$safe_root/tests/dependents/create_apt_smoke_repo.sh" \
  "$safe_root/tests/dependents/create_dpkg_smoke_package.sh" \
  "$safe_root/tests/dependents/libarchive_tools_smoke.sh" \
  "$safe_root/tests/upstream/test_compress.sh" \
  "$safe_root/tests/upstream/test_files.sh" \
  "$safe_root/tests/upstream/test_scripts.sh" \
  "$safe_root/tests/upstream/test_compress_generated_abc" \
  "$safe_root/tests/upstream/test_compress_generated_random" \
  "$safe_root/tests/upstream/test_compress_generated_text" \
  "$safe_root/tests/upstream/test_compress_prepared_bcj_sparc" \
  "$safe_root/tests/upstream/test_compress_prepared_bcj_x86"

python3 - <<'PY' "$library_tests_root/fixtures/dependents.json"
from pathlib import Path
import json
import sys

expected = [
    "dpkg",
    "apt",
    "python3.12",
    "libxml2",
    "libtiff6",
    "squashfs-tools",
    "kmod",
    "gdb",
    "libarchive13t64",
    "libarchive-tools",
    "mariadb-plugin-provider-lzma",
    "libboost-iostreams1.83.0",
]
actual = [entry["binary_package"] for entry in json.loads(Path(sys.argv[1]).read_text())["dependents"]]
if actual != expected:
    raise SystemExit(f"unexpected liblzma dependent matrix: {actual}")
PY

LIBLZMA_DEPENDENT_TEST_ROOT="$work_root" \
  python3 "$safe_root/tests/dependents/python_lzma_smoke.py" >"$work_root/python.log"
grep -F "python lzma ok" "$work_root/python.log" >/dev/null

g++ \
  -std=c++17 \
  -Wall \
  -Wextra \
  "$safe_root/tests/dependents/boost_iostreams_smoke.cpp" \
  -lboost_iostreams \
  -llzma \
  -o "$work_root/boost_iostreams_smoke"
"$work_root/boost_iostreams_smoke" >"$work_root/boost.log"
grep -F "boost lzma ok" "$work_root/boost.log" >/dev/null

cc \
  -std=c11 \
  -Wall \
  -Wextra \
  "$safe_root/tests/dependents/libtiff_smoke.c" \
  $(pkg-config --cflags --libs libtiff-4) \
  -llzma \
  -o "$work_root/libtiff_smoke"
"$work_root/libtiff_smoke" "$work_root/lzma.tiff" >"$work_root/libtiff.log"
grep -F "libtiff lzma ok" "$work_root/libtiff.log" >/dev/null

cc \
  -std=c11 \
  -Wall \
  -Wextra \
  "$safe_root/tests/dependents/gdb_smoke.c" \
  -llzma \
  -o "$work_root/gdb_smoke"
"$work_root/gdb_smoke" >/dev/null

bash "$safe_root/tests/dependents/libarchive_tools_smoke.sh" "$work_root/libarchive-tools" >"$work_root/libarchive-tools.log"
grep -F "libarchive tools ok" "$work_root/libarchive-tools.log" >/dev/null

dpkg_smoke_deb="$(bash "$safe_root/tests/dependents/create_dpkg_smoke_package.sh" "$work_root/dpkg-smoke")"
dpkg-deb --info "$dpkg_smoke_deb" >"$work_root/dpkg.info"
grep -F "Package: liblzma-smoke" "$work_root/dpkg.info" >/dev/null

bash "$safe_root/tests/dependents/create_apt_smoke_repo.sh" "$work_root/apt-smoke"
(
  cd "$work_root/apt-smoke/repo"
  python3 -m http.server 18080 >"$work_root/apt-smoke/http.log" 2>&1 &
  server_pid=$!
  trap 'kill "$server_pid" >/dev/null 2>&1 || true; wait "$server_pid" >/dev/null 2>&1 || true' EXIT
  sleep 1
  apt-get \
    -o Dir::State="$work_root/apt-smoke/root/state" \
    -o Dir::Cache="$work_root/apt-smoke/root/cache" \
    -o Dir::Etc::sourcelist="$work_root/apt-smoke/root/etc/apt/sources.list" \
    -o Dir::Etc::sourceparts="$work_root/apt-smoke/root/etc/apt/sources.list.d" \
    -o APT::Architecture=amd64 \
    update >"$work_root/apt-smoke/update.log" 2>&1
  apt-cache \
    -o Dir::State="$work_root/apt-smoke/root/state" \
    -o Dir::Cache="$work_root/apt-smoke/root/cache" \
    -o Dir::Etc::sourcelist="$work_root/apt-smoke/root/etc/apt/sources.list" \
    -o Dir::Etc::sourceparts="$work_root/apt-smoke/root/etc/apt/sources.list.d" \
    -o APT::Architecture=amd64 \
    show liblzma-apt-smoke >"$work_root/apt-smoke/show.log" 2>&1
)
grep -F "Package: liblzma-apt-smoke" "$work_root/apt-smoke/show.log" >/dev/null

run_skip_ok() {
  local status=0

  set +e
  "$@"
  status=$?
  set -e

  if [[ $status -ne 0 && $status -ne 77 ]]; then
    return "$status"
  fi
}

compile_liblzma_test() {
  local source_path=$1
  local output_path=$2
  shift 2

  cc \
    -std=c11 \
    -D_GNU_SOURCE \
    -Wall \
    -Wextra \
    -I"$safe_root/tests/upstream" \
    -I/usr/include \
    "$source_path" \
    -llzma \
    -lpthread \
    "$@" \
    -o "$output_path"
}

compile_liblzma_test \
  "$safe_root/tests/upstream/test_public_api.c" \
  "$work_root/test_public_api"
export srcdir="$safe_root/tests/upstream"
run_skip_ok "$work_root/test_public_api"

compile_liblzma_test \
  "$safe_root/tests/upstream/test_stream_flags.c" \
  "$work_root/test_stream_flags"
run_skip_ok "$work_root/test_stream_flags"

compile_liblzma_test \
  "$safe_root/tests/upstream/test_vli.c" \
  "$work_root/test_vli"
run_skip_ok "$work_root/test_vli"

compile_liblzma_test \
  "$safe_root/tests/extra/test_mt_api.c" \
  "$work_root/test_mt_api"
run_skip_ok "$work_root/test_mt_api"

compile_liblzma_test \
  "$safe_root/tests/extra/test_mt_regressions.c" \
  "$work_root/test_mt_regressions"
run_skip_ok "$work_root/test_mt_regressions"

compile_liblzma_test \
  "$safe_root/tests/extra/test_microlzma.c" \
  "$work_root/test_microlzma"
run_skip_ok "$work_root/test_microlzma"

compile_liblzma_test \
  "$safe_root/tests/extra/test_file_info_decoder.c" \
  "$work_root/test_file_info_decoder" \
  "-DSAFE_TEST_FILES_DIR=\"$safe_root/tests/upstream/files\""
run_skip_ok "$work_root/test_file_info_decoder"

cc -std=c99 -Wall -Wextra "$safe_root/tests/upstream/bcj_test.c" -o "$work_root/bcj_test"
"$work_root/bcj_test"

run_skip_ok bash "$safe_root/tests/upstream/test_files.sh"
run_skip_ok bash "$safe_root/tests/upstream/test_scripts.sh"
