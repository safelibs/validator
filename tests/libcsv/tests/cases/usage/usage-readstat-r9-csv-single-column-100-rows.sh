#!/usr/bin/env bash
# @testcase: usage-readstat-r9-csv-single-column-100-rows
# @title: readstat single column 100 rows
# @description: Converts a 100-row single-column CSV through DTA and confirms the row count and a representative middle value are preserved.
# @timeout: 180
# @tags: usage, csv, large
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

{
  printf 'value\n'
  for i in $(seq 1 100); do printf '%d\n' "$i"; done
} >"$tmpdir/in.csv"

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"NUMERIC","name":"value","label":"V"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"
readstat "$tmpdir/out.dta" >"$tmpdir/summary"
validator_assert_contains "$tmpdir/summary" 'Columns: 1'
validator_assert_contains "$tmpdir/summary" 'Rows: 100'

readstat "$tmpdir/out.dta" - >"$tmpdir/out.csv"
validator_assert_contains "$tmpdir/out.csv" '50.000000'
validator_assert_contains "$tmpdir/out.csv" '100.000000'
