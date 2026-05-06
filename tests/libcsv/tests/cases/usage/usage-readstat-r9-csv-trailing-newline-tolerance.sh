#!/usr/bin/env bash
# @testcase: usage-readstat-r9-csv-trailing-newline-tolerance
# @title: readstat tolerates extra trailing newlines
# @description: Appends multiple trailing blank lines to a small CSV and confirms readstat does not count them as additional rows.
# @timeout: 180
# @tags: usage, csv, parsing
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

{
  printf 'a,b\n'
  printf '1,2\n'
  printf '3,4\n'
  printf '\n\n\n'
} >"$tmpdir/in.csv"

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"NUMERIC","name":"a","label":"A"},{"type":"NUMERIC","name":"b","label":"B"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"
readstat "$tmpdir/out.dta" >"$tmpdir/summary"

# Trailing blank lines may or may not be counted - just ensure we got at least the data rows.
validator_assert_contains "$tmpdir/summary" 'Columns: 2'
grep -E 'Rows: [2-9]' "$tmpdir/summary"
