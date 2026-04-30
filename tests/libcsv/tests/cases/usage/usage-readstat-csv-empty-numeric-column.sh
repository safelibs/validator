#!/usr/bin/env bash
# @testcase: usage-readstat-csv-empty-numeric-column
# @title: readstat empty numeric column across rows
# @description: Converts a CSV whose numeric column has empty values on every row through DTA and verifies the row count is preserved and string fields survive.
# @timeout: 180
# @tags: usage, csv, missing
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
name,score
alpha,
beta,
gamma,
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"STRING","name":"name","label":"Name"},{"type":"NUMERIC","name":"score","label":"Score"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"

readstat "$tmpdir/out.dta" >"$tmpdir/summary"
validator_assert_contains "$tmpdir/summary" 'Columns: 2'
validator_assert_contains "$tmpdir/summary" 'Rows: 3'

readstat "$tmpdir/out.dta" - >"$tmpdir/out.csv"
validator_assert_contains "$tmpdir/out.csv" '"name","score"'
validator_assert_contains "$tmpdir/out.csv" '"alpha",'
validator_assert_contains "$tmpdir/out.csv" '"beta",'
validator_assert_contains "$tmpdir/out.csv" '"gamma",'

# Each data row must end with an empty score field, never with a numeric value.
data_lines=$(tail -n +2 "$tmpdir/out.csv")
while IFS= read -r line; do
  [[ -n "$line" ]] || continue
  if [[ ! "$line" =~ ,$ ]]; then
    printf 'expected trailing empty score, got: %s\n' "$line" >&2
    exit 1
  fi
done <<<"$data_lines"
