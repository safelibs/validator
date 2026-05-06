#!/usr/bin/env bash
# @testcase: usage-readstat-r9-csv-many-string-rows
# @title: readstat 200 string rows
# @description: Stores 200 short string rows into Stata DTA via readstat and verifies the row count and a known cell are preserved on read-back.
# @timeout: 240
# @tags: usage, csv, strings
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

{
  printf 'name\n'
  for i in $(seq 1 200); do printf 'item%03d\n' "$i"; done
} >"$tmpdir/in.csv"

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"STRING","name":"name","label":"N"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"
readstat "$tmpdir/out.dta" >"$tmpdir/summary"
validator_assert_contains "$tmpdir/summary" 'Columns: 1'
validator_assert_contains "$tmpdir/summary" 'Rows: 200'

readstat "$tmpdir/out.dta" - >"$tmpdir/out.csv"
validator_assert_contains "$tmpdir/out.csv" 'item001'
validator_assert_contains "$tmpdir/out.csv" 'item100'
validator_assert_contains "$tmpdir/out.csv" 'item200'
