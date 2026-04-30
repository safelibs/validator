#!/usr/bin/env bash
# @testcase: usage-readstat-csv-mixed-numeric-string-padding
# @title: readstat mixed numeric and string columns with varying string widths
# @description: Builds a CSV with one numeric column and one string column where string values vary in length from 1 to 12 characters, converts through DTA, and verifies each string value reappears verbatim alongside its paired numeric value rendered to six decimals.
# @timeout: 180
# @tags: usage, csv, mixed
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
label,score
a,1
ab,2
abcde,3
abcdefghijkl,4
xy,5
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"STRING","name":"label","label":"Label"},{"type":"NUMERIC","name":"score","label":"Score"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"
readstat "$tmpdir/out.dta" - >"$tmpdir/out.csv"

validator_assert_contains "$tmpdir/out.csv" '"label","score"'
validator_assert_contains "$tmpdir/out.csv" '"a",1.000000'
validator_assert_contains "$tmpdir/out.csv" '"ab",2.000000'
validator_assert_contains "$tmpdir/out.csv" '"abcde",3.000000'
validator_assert_contains "$tmpdir/out.csv" '"abcdefghijkl",4.000000'
validator_assert_contains "$tmpdir/out.csv" '"xy",5.000000'

# Strings must not be padded with trailing spaces inside the quoted CSV.
if grep -E '"[a-z]+ +"' "$tmpdir/out.csv" >/dev/null; then
  printf 'unexpected whitespace padding inside quoted strings\n' >&2
  cat "$tmpdir/out.csv" >&2
  exit 1
fi

readstat "$tmpdir/out.dta" >"$tmpdir/summary"
validator_assert_contains "$tmpdir/summary" 'Columns: 2'
validator_assert_contains "$tmpdir/summary" 'Rows: 5'
