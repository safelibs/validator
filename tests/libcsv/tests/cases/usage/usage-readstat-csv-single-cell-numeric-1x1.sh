#!/usr/bin/env bash
# @testcase: usage-readstat-csv-single-cell-numeric-1x1
# @title: readstat 1x1 CSV with numeric value
# @description: Converts a CSV containing exactly one numeric column and one numeric data row (the value 17) through DTA and verifies the summary reports Columns 1 and Rows 1, the readback header is the bare numeric column name and the single data line is the six-decimal short form of 17, distinguishing this numeric 1x1 case from the existing string-flavoured 1x1 test.
# @timeout: 180
# @tags: usage, csv, minimal, numeric
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
value
17
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"NUMERIC","name":"value","label":"Value"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"
validator_require_file "$tmpdir/out.dta"

readstat "$tmpdir/out.dta" >"$tmpdir/summary"
validator_assert_contains "$tmpdir/summary" 'Columns: 1'
validator_assert_contains "$tmpdir/summary" 'Rows: 1'

readstat "$tmpdir/out.dta" - >"$tmpdir/out.csv"

# Exactly two lines: header and single data row.
total=$(wc -l <"$tmpdir/out.csv")
[[ "$total" == "2" ]] || {
  printf 'expected 2 output lines, got %s\n' "$total" >&2
  cat "$tmpdir/out.csv" >&2
  exit 1
}

header=$(sed -n '1p' "$tmpdir/out.csv")
[[ "$header" == '"value"' ]] || {
  printf 'unexpected header: %s\n' "$header" >&2
  exit 1
}

data=$(sed -n '2p' "$tmpdir/out.csv")
# Numeric 1x1 must NOT be quoted (string 1x1 would be).
[[ "$data" == "17.000000" ]] || {
  printf 'unexpected single numeric value: %s\n' "$data" >&2
  exit 1
}

# Defence: data row must not be a quoted string form like "17".
if grep -E '^"17' "$tmpdir/out.csv" >/dev/null; then
  printf 'numeric 1x1 was rendered as a quoted string\n' >&2
  cat "$tmpdir/out.csv" >&2
  exit 1
fi
