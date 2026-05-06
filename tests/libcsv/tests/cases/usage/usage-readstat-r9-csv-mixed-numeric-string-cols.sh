#!/usr/bin/env bash
# @testcase: usage-readstat-r9-csv-mixed-numeric-string-cols
# @title: readstat mixed numeric and string columns
# @description: Builds a CSV with one numeric and two string columns, converts to DTA, and confirms both column kinds are preserved on readback.
# @timeout: 180
# @tags: usage, csv, types
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
id,first,last
1,Alice,Smith
2,Bob,Jones
3,Carol,Davis
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[
  {"type":"NUMERIC","name":"id","label":"ID"},
  {"type":"STRING","name":"first","label":"F"},
  {"type":"STRING","name":"last","label":"L"}
]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"
readstat "$tmpdir/out.dta" >"$tmpdir/summary"
validator_assert_contains "$tmpdir/summary" 'Columns: 3'
validator_assert_contains "$tmpdir/summary" 'Rows: 3'

readstat "$tmpdir/out.dta" - >"$tmpdir/out.csv"
validator_assert_contains "$tmpdir/out.csv" '1.000000,"Alice","Smith"'
validator_assert_contains "$tmpdir/out.csv" '2.000000,"Bob","Jones"'
validator_assert_contains "$tmpdir/out.csv" '3.000000,"Carol","Davis"'
