#!/usr/bin/env bash
set -euo pipefail

source /validator/tests/_shared/runtime_helpers.sh

readonly tagged_root=${VALIDATOR_TAGGED_ROOT:?}
readonly library_tests_root="${VALIDATOR_LIBRARY_ROOT:?}/tests"
readonly work_root=$(mktemp -d)
readonly safe_root="$work_root/safe"
readonly original_root="$work_root/original"

cleanup() {
  rm -rf "$work_root"
}
trap cleanup EXIT

validator_require_file "$library_tests_root/fixtures/dependents.json"
validator_require_file "$library_tests_root/harness-source/original-test-script.sh"
validator_require_dir "$tagged_root/safe/tests"
validator_require_dir "$tagged_root/safe/debian/tests"
validator_require_dir "$tagged_root/safe/scripts"
validator_require_dir "$tagged_root/original"
validator_require_file "$tagged_root/original/public_api_test.c"
validator_require_file "$tagged_root/safe/scripts/run-debian-tests.sh"

validator_copy_tree "$tagged_root/safe/tests" "$safe_root/tests"
validator_copy_tree "$tagged_root/safe/debian/tests" "$safe_root/debian/tests"
validator_copy_tree "$tagged_root/safe/scripts" "$safe_root/scripts"
validator_copy_tree "$tagged_root/original" "$original_root"

chmod +x \
  "$safe_root/debian/tests/bzexe-test" \
  "$safe_root/debian/tests/compare" \
  "$safe_root/debian/tests/compress" \
  "$safe_root/debian/tests/grep" \
  "$safe_root/debian/tests/link-with-shared"

python3 - <<'PY' "$library_tests_root/fixtures/dependents.json"
from pathlib import Path
import json
import sys

expected = [
    "libapt-pkg6.0t64",
    "bzip2",
    "libpython3.12-stdlib",
    "php8.3-bz2",
    "pike8.0-bzip2",
    "libcompress-raw-bzip2-perl",
    "mariadb-plugin-provider-bzip2",
    "gpg",
    "zip",
    "unzip",
    "libarchive13t64",
    "libfreetype6",
    "gstreamer1.0-plugins-good",
]
actual = [entry["binary_package"] for entry in json.loads(Path(sys.argv[1]).read_text())["dependents"]]
if actual != expected:
    raise SystemExit(f"unexpected libbz2 dependent matrix: {actual}")
PY

for sample in 1 2 3; do
  bzip2 -dc "$original_root/sample${sample}.bz2" >"$work_root/sample${sample}.out"
  cmp "$work_root/sample${sample}.out" "$original_root/sample${sample}.ref"
done

cc \
  -std=c99 \
  -Wall \
  -Wextra \
  -I"$original_root" \
  "$original_root/public_api_test.c" \
  -lbz2 \
  -o "$work_root/public_api_test"
"$work_root/public_api_test"

for test_name in compress compare grep link-with-shared bzexe-test; do
  export AUTOPKGTEST_TMP="$work_root/autopkg/$test_name"
  rm -rf "$AUTOPKGTEST_TMP"
  mkdir -p "$AUTOPKGTEST_TMP"
  bash "$safe_root/debian/tests/$test_name"
done

python3 - <<'PY' "$safe_root/tests"
from pathlib import Path
import sys

required = {
    "abi_contract.rs",
    "compression_port.rs",
    "decompress_port.rs",
    "dependents.rs",
    "golden_streams.rs",
    "link_contract.rs",
}
actual = {path.name for path in Path(sys.argv[1]).iterdir() if path.is_file()}
missing = sorted(required - actual)
if missing:
    raise SystemExit(f"missing copied validator-facing probes: {missing}")
PY
