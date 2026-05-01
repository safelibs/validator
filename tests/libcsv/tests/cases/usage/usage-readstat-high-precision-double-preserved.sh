#!/usr/bin/env bash
# @testcase: usage-readstat-high-precision-double-preserved
# @title: readstat preserves 14-digit double precision through DTA round-trip
# @description: Round-trips three irrational mathematical constants (pi, e, sqrt(2)) carried to fourteen digits past the decimal point through CSV to DTA and back to CSV, and verifies every output digit string matches the input character-for-character so no precision is silently truncated by the readstat numeric pipeline.
# @timeout: 120
# @tags: usage, csv, precision, double
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
id,value
1,3.14159265358979
2,2.71828182845905
3,1.41421356237309
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"NUMERIC","name":"id","label":"ID"},{"type":"NUMERIC","name":"value","label":"Value"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"
readstat "$tmpdir/out.dta" - >"$tmpdir/back.csv"

# Header line check.
validator_assert_contains "$tmpdir/back.csv" '"id","value"'

# Each constant must appear in full precision in the output.
validator_assert_contains "$tmpdir/back.csv" '3.14159265358979'
validator_assert_contains "$tmpdir/back.csv" '2.71828182845905'
validator_assert_contains "$tmpdir/back.csv" '1.41421356237309'

# Output must contain exactly three data rows.
data_rows=$(grep -cE '^[0-9.]+,[0-9.]+$' "$tmpdir/back.csv")
if [[ "$data_rows" != "3" ]]; then
  printf 'expected exactly 3 data rows, got %s\n' "$data_rows" >&2
  cat "$tmpdir/back.csv" >&2
  exit 1
fi
