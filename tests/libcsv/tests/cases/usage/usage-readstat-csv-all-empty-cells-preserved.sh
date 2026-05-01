#!/usr/bin/env bash
# @testcase: usage-readstat-csv-all-empty-cells-preserved
# @title: readstat preserves rows where every cell is empty
# @description: Builds a DTA from a CSV containing two rows in which every cell is empty for both a STRING column and a NUMERIC column and verifies the round-tripped CSV retains both empty rows with empty quoted strings for the string column and empty numeric placeholders for the numeric column.
# @timeout: 120
# @tags: usage, csv, empty, missing
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
name,score
,
,
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"STRING","name":"name","label":"Name"},{"type":"NUMERIC","name":"score","label":"Score"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"
readstat "$tmpdir/out.dta" >"$tmpdir/summary"
validator_assert_contains "$tmpdir/summary" 'Columns: 2'
validator_assert_contains "$tmpdir/summary" 'Rows: 2'

readstat "$tmpdir/out.dta" - >"$tmpdir/back.csv"

# Header preserved.
validator_assert_contains "$tmpdir/back.csv" '"name","score"'

# Both data rows must encode an empty string in column 1 and an empty numeric in column 2.
empty_rows=$(grep -cE '^"",$' "$tmpdir/back.csv")
if [[ "$empty_rows" != "2" ]]; then
  printf 'expected exactly 2 empty data rows, got %s\n' "$empty_rows" >&2
  cat "$tmpdir/back.csv" >&2
  exit 1
fi
