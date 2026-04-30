#!/usr/bin/env bash
# @testcase: usage-readstat-csv-all-zeros-multi-row
# @title: readstat CSV numeric column with all zero rows
# @description: Builds a CSV whose numeric column holds zero on every one of five rows, converts through DTA, and verifies each readback row reports a numeric zero in the six-decimal short form rather than an empty value or unrelated number.
# @timeout: 180
# @tags: usage, csv, numeric, zero
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
name,score
row_a,0
row_b,0
row_c,0
row_d,0
row_e,0
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"STRING","name":"name","label":"Name"},{"type":"NUMERIC","name":"score","label":"Score"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"

readstat "$tmpdir/out.dta" >"$tmpdir/summary"
validator_assert_contains "$tmpdir/summary" 'Columns: 2'
validator_assert_contains "$tmpdir/summary" 'Rows: 5'

readstat "$tmpdir/out.dta" - >"$tmpdir/out.csv"
validator_assert_contains "$tmpdir/out.csv" '"name","score"'

# Each of the five data rows must report 0.000000 explicitly.
for tag in row_a row_b row_c row_d row_e; do
  validator_assert_contains "$tmpdir/out.csv" "\"$tag\",0.000000"
done

# Count zero occurrences: exactly five 0.000000 values, one per row.
zero_count=$(grep -c ',0\.000000$' "$tmpdir/out.csv")
[[ "$zero_count" == "5" ]] || {
  printf 'expected 5 zero-suffixed rows, got %s\n' "$zero_count" >&2
  cat "$tmpdir/out.csv" >&2
  exit 1
}

# No row may end with an empty value (which would mean the numeric was lost).
if grep -q ',$' "$tmpdir/out.csv"; then
  printf 'unexpected empty trailing field in output\n' >&2
  cat "$tmpdir/out.csv" >&2
  exit 1
fi
