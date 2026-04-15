#!/usr/bin/env bash
set -euo pipefail

source /validator/tests/_shared/runtime_helpers.sh

readonly tagged_root=${VALIDATOR_TAGGED_ROOT:?}
readonly library_tests_root="${VALIDATOR_LIBRARY_ROOT:?}/tests"
readonly work_root=$(mktemp -d)
readonly safe_root="$work_root/safe"
readonly original_root="$work_root/original"
readonly copied_scripts_root="$tagged_root/safe/scripts"
readonly copied_docker_root="$tagged_root/safe/docker"
readonly pkg_config_flags=$(pkg-config --cflags --libs libzstd)

cleanup() {
  rm -rf "$work_root"
}
trap cleanup EXIT

validator_require_dir "$tagged_root/safe/tests/dependents"
validator_require_dir "$tagged_root/safe/tests/capi"
validator_require_dir "$tagged_root/safe/tests/link-compat"
validator_require_dir "$tagged_root/safe/tests/ported"
validator_require_dir "$copied_scripts_root"
validator_require_dir "$copied_docker_root"
validator_require_dir "$tagged_root/original/libzstd-1.5.5+dfsg2"
validator_require_file "$tagged_root/safe/scripts/run-dependent-matrix.sh"
validator_require_file "$tagged_root/safe/tests/dependents/dependent_matrix.toml"
validator_require_file "$tagged_root/safe/tests/link-compat/run_zstreamtest.c"
validator_require_file "$tagged_root/safe/tests/ported/whitebox/offline_regression_data.c"

validator_copy_tree "$tagged_root/safe/tests" "$safe_root/tests"
validator_copy_tree "$tagged_root/safe/scripts" "$safe_root/scripts"
validator_copy_tree "$tagged_root/original/libzstd-1.5.5+dfsg2" "$original_root/libzstd-1.5.5+dfsg2"

python3 - <<'PY' "$library_tests_root/fixtures/dependents.json" "$tagged_root/safe/tests/dependents/dependent_matrix.toml"
from pathlib import Path
import json
import sys
import tomllib

expected = [
    "apt",
    "dpkg",
    "rsync",
    "systemd",
    "libarchive",
    "btrfs-progs",
    "squashfs-tools",
    "qemu",
    "curl",
    "tiff",
    "rpm",
    "zarchive",
]
dependents = json.loads(Path(sys.argv[1]).read_text())["packages"]
matrix = tomllib.loads(Path(sys.argv[2]).read_text())
actual_json = [entry["source_package"] for entry in dependents]
actual_toml = [entry["source_package"] for entry in matrix["dependent"]]
if actual_json != expected or actual_toml != expected:
    raise SystemExit(f"unexpected libzstd dependent matrix: json={actual_json} toml={actual_toml}")
PY

compile_c() {
  local output_path=$1
  shift
  cc \
    -std=c11 \
    -Wall \
    -Wextra \
    -D_POSIX_C_SOURCE=200809L \
    -Wno-deprecated-declarations \
    -Wno-unused-function \
    -Wno-unused-parameter \
    -include sys/types.h \
    -I"$safe_root/tests/capi" \
    -I"$original_root/libzstd-1.5.5+dfsg2/lib" \
    -I"$original_root/libzstd-1.5.5+dfsg2/programs" \
    -I"$original_root/libzstd-1.5.5+dfsg2/tests" \
    -I"$original_root/libzstd-1.5.5+dfsg2/tests/regression" \
    -I"$original_root/libzstd-1.5.5+dfsg2/tests/fuzz" \
    "$@" \
    $pkg_config_flags \
    -lpthread \
    -o "$output_path"
}

compile_c \
  "$work_root/frame_probe" \
  "$safe_root/tests/capi/frame_probe.c"
"$work_root/frame_probe" \
  "$original_root/libzstd-1.5.5+dfsg2/tests/golden-decompression/rle-first-block.zst" \
  "$original_root/libzstd-1.5.5+dfsg2/tests/golden-decompression/empty-block.zst"

compile_c \
  "$work_root/legacy_decode" \
  "$safe_root/tests/capi/legacy_decode.c"
"$work_root/legacy_decode"

compile_c \
  "$work_root/invalid_dictionaries_driver" \
  "$safe_root/tests/capi/invalid_dictionaries_driver.c"
"$work_root/invalid_dictionaries_driver"

compile_c \
  "$work_root/bigdict_driver" \
  "$safe_root/tests/capi/bigdict_driver.c"
"$work_root/bigdict_driver"

compile_c \
  "$work_root/paramgrill_driver" \
  "$safe_root/tests/capi/paramgrill_driver.c"
"$work_root/paramgrill_driver"

compile_c \
  "$work_root/external_matchfinder_driver" \
  "$safe_root/tests/capi/external_matchfinder_driver.c"
"$work_root/external_matchfinder_driver"

compile_c \
  "$work_root/dict_builder_driver" \
  "$safe_root/tests/capi/dict_builder_driver.c"
"$work_root/dict_builder_driver"

compile_c \
  "$work_root/simple_compression" \
  "$original_root/libzstd-1.5.5+dfsg2/examples/simple_compression.c"
compile_c \
  "$work_root/simple_decompression" \
  "$original_root/libzstd-1.5.5+dfsg2/examples/simple_decompression.c"
"$work_root/simple_compression" "$original_root/libzstd-1.5.5+dfsg2/README.md"
"$work_root/simple_decompression" "$original_root/libzstd-1.5.5+dfsg2/README.md.zst"

compile_c \
  "$work_root/zstreamtest_upstream.o" \
  -Dmain=upstream_zstreamtest_main \
  -c \
  "$original_root/libzstd-1.5.5+dfsg2/tests/zstreamtest.c"
compile_c \
  "$work_root/run_zstreamtest" \
  "$safe_root/tests/link-compat/run_zstreamtest.c" \
  "$work_root/zstreamtest_upstream.o"
"$work_root/run_zstreamtest"

compile_c \
  "$work_root/pooltests_upstream.o" \
  -Dmain=upstream_poolTests_main \
  -c \
  "$original_root/libzstd-1.5.5+dfsg2/tests/poolTests.c"
compile_c \
  "$work_root/run_pooltests" \
  "$safe_root/tests/link-compat/run_pooltests.c" \
  "$work_root/pooltests_upstream.o"
"$work_root/run_pooltests"

compile_c \
  "$work_root/offline_regression" \
  "$safe_root/tests/ported/whitebox/offline_regression_data.c" \
  "$original_root/libzstd-1.5.5+dfsg2/tests/regression/config.c" \
  "$original_root/libzstd-1.5.5+dfsg2/tests/regression/method.c" \
  "$original_root/libzstd-1.5.5+dfsg2/tests/regression/result.c" \
  "$original_root/libzstd-1.5.5+dfsg2/tests/regression/test.c" \
  "$original_root/libzstd-1.5.5+dfsg2/programs/util.c"

python3 - <<'PY' "$tagged_root/safe/tests/dependents/dependent_matrix.toml" "$work_root/dependents"
from pathlib import Path
import json
import shlex
import subprocess
import sys
import tomllib

matrix = tomllib.loads(Path(sys.argv[1]).read_text())
out_root = Path(sys.argv[2])
out_root.mkdir(parents=True, exist_ok=True)
tagged_root = Path("/validator/tests/libzstd/tests/tagged-port")

for entry in matrix["dependent"]:
    src = tagged_root / entry["compile_probe"]
    exe = out_root / entry["source_package"]
    modules = entry.get("pkg_config_modules", [])
    flags = []
    if modules:
        flags = subprocess.check_output(
            ["pkg-config", "--cflags", "--libs", *modules],
            text=True,
        ).split()
    cmd = [
        "cc",
        "-std=c11",
        "-Wall",
        "-Wextra",
        str(src),
        "-o",
        str(exe),
        *flags,
    ]
    subprocess.run(cmd, check=True)
PY

regression_cache="$work_root/offline-regression-cache"
mkdir -p "$regression_cache/silesia" "$regression_cache/github"
cp \
  "$original_root/libzstd-1.5.5+dfsg2/README.md" \
  "$regression_cache/silesia/root-README.md"
cp \
  "$original_root/libzstd-1.5.5+dfsg2/doc/README.md" \
  "$regression_cache/silesia/doc-README.md"
cp \
  "$original_root/libzstd-1.5.5+dfsg2/examples/simple_compression.c" \
  "$regression_cache/github/simple_compression.c"
cp \
  "$original_root/libzstd-1.5.5+dfsg2/tests/zstreamtest.c" \
  "$regression_cache/github/zstreamtest.c"
tar -cf "$regression_cache/silesia.tar" -C "$regression_cache" silesia
tar -cf "$regression_cache/github.tar" -C "$regression_cache" github
cp \
  "$original_root/libzstd-1.5.5+dfsg2/tests/golden-dictionaries/http-dict-missing-symbols" \
  "$regression_cache/github.dict"
cp \
  "$original_root/libzstd-1.5.5+dfsg2/tests/golden-dictionaries/http-dict-missing-symbols" \
  "$regression_cache/github.tar.dict"
"$work_root/offline_regression" \
  --cache "$regression_cache" \
  --output "$work_root/offline_regression_results.csv" \
  --zstd "$(command -v zstd)"
test -s "$work_root/offline_regression_results.csv"
