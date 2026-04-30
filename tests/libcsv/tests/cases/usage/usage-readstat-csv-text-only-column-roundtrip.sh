#!/usr/bin/env bash
# @testcase: usage-readstat-csv-text-only-column-roundtrip
# @title: readstat text-only string column preserved through DTA
# @description: Converts a CSV containing a single string-typed column with four distinct ASCII labels through DTA and verifies every label reappears verbatim and in the same order on readback.
# @timeout: 180
# @tags: usage, csv, string
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
label
alpha
bravo
charlie
delta
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"STRING","name":"label","label":"Label"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"
readstat "$tmpdir/out.dta" - >"$tmpdir/out.csv"

validator_assert_contains "$tmpdir/out.csv" '"label"'
validator_assert_contains "$tmpdir/out.csv" '"alpha"'
validator_assert_contains "$tmpdir/out.csv" '"bravo"'
validator_assert_contains "$tmpdir/out.csv" '"charlie"'
validator_assert_contains "$tmpdir/out.csv" '"delta"'

# Order must be preserved.
positions=$(grep -nE '"alpha"|"bravo"|"charlie"|"delta"' "$tmpdir/out.csv" | cut -d: -f1 | tr '\n' ' ')
[[ "$positions" == "2 3 4 5 " ]] || {
  printf 'expected labels on lines 2..5 in order, got: %s\n' "$positions" >&2
  cat "$tmpdir/out.csv" >&2
  exit 1
}

# Total of header + 4 rows.
total=$(wc -l <"$tmpdir/out.csv")
[[ "$total" == "5" ]] || {
  printf 'expected 5 lines, got %s\n' "$total" >&2
  exit 1
}

readstat "$tmpdir/out.dta" >"$tmpdir/summary"
validator_assert_contains "$tmpdir/summary" 'Columns: 1'
validator_assert_contains "$tmpdir/summary" 'Rows: 4'
