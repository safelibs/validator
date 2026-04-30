#!/usr/bin/env bash
# @testcase: usage-readstat-csv-trailing-empty-lines
# @title: readstat CSV with trailing empty lines
# @description: Converts a CSV that ends with several blank lines through DTA and verifies the trailing blanks do not inflate the row count.
# @timeout: 180
# @tags: usage, csv, blank-lines
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Two real rows then four empty trailing lines.
printf 'name,score\nalpha,1\nbeta,2\n\n\n\n\n' >"$tmpdir/in.csv"

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"STRING","name":"name","label":"Name"},{"type":"NUMERIC","name":"score","label":"Score"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"

readstat "$tmpdir/out.dta" >"$tmpdir/summary"
validator_assert_contains "$tmpdir/summary" 'Columns: 2'
# Only the two real rows must be counted; empty trailing lines must not become rows.
validator_assert_contains "$tmpdir/summary" 'Rows: 2'

readstat "$tmpdir/out.dta" - >"$tmpdir/out.csv"
validator_assert_contains "$tmpdir/out.csv" '"alpha",1.000000'
validator_assert_contains "$tmpdir/out.csv" '"beta",2.000000'

# Header + 2 data rows = 3 lines exactly.
total=$(wc -l <"$tmpdir/out.csv")
[[ "$total" == "3" ]] || {
  printf 'expected 3 output lines, got %s\n' "$total" >&2
  cat "$tmpdir/out.csv" >&2
  exit 1
}
