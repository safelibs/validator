#!/usr/bin/env bash
# @testcase: usage-readstat-csv-sentinel-row1-col1
# @title: readstat sentinel value at row 1 column 1 preserved exactly
# @description: Builds a CSV where the very first data cell (row 1, column 1) carries a unique sentinel numeric value (271828) surrounded by zeros, converts through DTA, and verifies the readback line 2 (data row 1) has the sentinel in field 1 and zeros in subsequent fields, that the sentinel appears exactly once in the entire output, and that no other data row has any non-zero value in column 1.
# @timeout: 180
# @tags: usage, csv, sentinel, addressing
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
a,b,c
271828,0,0
0,0,0
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"NUMERIC","name":"a","label":"A"},{"type":"NUMERIC","name":"b","label":"B"},{"type":"NUMERIC","name":"c","label":"C"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"
readstat "$tmpdir/out.dta" - >"$tmpdir/out.csv"

# Header on line 1, sentinel-bearing row on line 2.
header=$(sed -n '1p' "$tmpdir/out.csv")
[[ "$header" == '"a","b","c"' ]] || {
  printf 'unexpected header: %s\n' "$header" >&2
  exit 1
}

row1=$(sed -n '2p' "$tmpdir/out.csv")
expected='271828.000000,0.000000,0.000000'
[[ "$row1" == "$expected" ]] || {
  printf 'expected %s on line 2, got %s\n' "$expected" "$row1" >&2
  cat "$tmpdir/out.csv" >&2
  exit 1
}

# Field 1 of data row 1 is the sentinel (cut field 1, line 2).
field1=$(sed -n '2p' "$tmpdir/out.csv" | cut -d, -f1)
[[ "$field1" == "271828.000000" ]] || {
  printf 'expected field1 of row1 to be 271828.000000, got %s\n' "$field1" >&2
  exit 1
}

# Sentinel appears exactly once.
sentinel_count=$(grep -c '271828\.000000' "$tmpdir/out.csv")
[[ "$sentinel_count" == "1" ]] || {
  printf 'expected sentinel exactly once, got %s\n' "$sentinel_count" >&2
  exit 1
}

# Row 2 of data (line 3 of file) must be all zeros.
row2=$(sed -n '3p' "$tmpdir/out.csv")
[[ "$row2" == '0.000000,0.000000,0.000000' ]] || {
  printf 'expected zero row, got %s\n' "$row2" >&2
  exit 1
}

# Sentinel must not have leaked to column b or c on either row.
if grep -E '^[^,]*,271828\.' "$tmpdir/out.csv" >/dev/null; then
  printf 'sentinel leaked to column b\n' >&2
  cat "$tmpdir/out.csv" >&2
  exit 1
fi
if grep -E ',271828\.[0-9]+$' "$tmpdir/out.csv" >/dev/null; then
  printf 'sentinel leaked to column c\n' >&2
  cat "$tmpdir/out.csv" >&2
  exit 1
fi

readstat "$tmpdir/out.dta" >"$tmpdir/summary"
validator_assert_contains "$tmpdir/summary" 'Columns: 3'
validator_assert_contains "$tmpdir/summary" 'Rows: 2'
