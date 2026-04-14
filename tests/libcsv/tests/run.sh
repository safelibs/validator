#!/usr/bin/env bash
set -euo pipefail

source /validator/tests/_shared/runtime_helpers.sh

readonly tagged_root=${VALIDATOR_TAGGED_ROOT:?}
readonly work_root=$(mktemp -d)
readonly layout_root="$work_root/layout"
readonly bin_root="$work_root/bin"
readonly data_root="$work_root/data"

cleanup() {
  rm -rf "$work_root"
}
trap cleanup EXIT

validator_require_dir "$tagged_root/original/examples"
validator_require_dir "$tagged_root/safe/tests/c"
validator_require_dir "$tagged_root/safe/debian/tests"
validator_require_file "$tagged_root/original/test_csv.c"
validator_require_file "$tagged_root/original/csv.h"

mkdir -p "$layout_root/original" "$layout_root/safe" "$bin_root" "$data_root"
mkdir -p "$layout_root/safe/debian"
ln -s "$tagged_root/original/test_csv.c" "$layout_root/original/test_csv.c"
ln -s "$tagged_root/original/examples" "$layout_root/original/examples"
ln -s "$tagged_root/original/csv.h" "$layout_root/original/csv.h"
ln -s "$tagged_root/safe/tests" "$layout_root/safe/tests"
ln -s "$tagged_root/safe/debian/tests" "$layout_root/safe/debian/tests"

compile_c() {
  local output=$1
  shift
  cc \
    -std=c99 \
    -O2 \
    -Wall \
    -Wextra \
    -I"$layout_root/original" \
    "$@" \
    -lcsv \
    -o "$output"
}

cat >"$data_root/good.csv" <<'EOF'
alpha,beta
1,2
EOF

cat >"$data_root/bad.csv" <<'EOF'
"unterminated
EOF

compile_c "$bin_root/test_csv" "$layout_root/original/test_csv.c"
"$bin_root/test_csv"

for source in "$layout_root/original/examples"/*.c; do
  name=$(basename "${source%.c}")
  compile_c "$bin_root/$name" "$source"
done

"$bin_root/csvtest" <"$data_root/good.csv" >"$data_root/csvtest.out"

"$bin_root/csvinfo" "$data_root/good.csv" >"$data_root/csvinfo.out"

"$bin_root/csvvalid" "$data_root/good.csv" "$data_root/bad.csv" >"$data_root/csvvalid.out"

"$bin_root/csvfix" "$data_root/good.csv" "$data_root/fixed.csv"
test -s "$data_root/fixed.csv"

for name in abi_edges allocator_failures layout_probe public_header_smoke; do
  compile_c "$bin_root/$name" "$layout_root/safe/tests/c/$name.c"
  "$bin_root/$name"
done

mkdir -p "$work_root/autopkg"
AUTOPKGTEST_TMP="$work_root/autopkg" \
  bash "$layout_root/safe/debian/tests/build-examples"
