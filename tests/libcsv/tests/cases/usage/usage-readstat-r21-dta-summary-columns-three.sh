#!/usr/bin/env bash
# @testcase: usage-readstat-r21-dta-summary-columns-three
# @title: readstat summary of a three-column DTA reports Columns: 3
# @description: Builds a three-column CSV with Stata metadata declaring three NUMERIC variables, converts to DTA, captures the summary, and asserts it contains "Columns: 3" - locking in column-count summary reporting for three-column input specifically (existing tests cover one/two column counts).
# @timeout: 60
# @tags: usage, dta, summary, columns, r21
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
a,b,c
1,2,3
4,5,6
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[
  {"type":"NUMERIC","name":"a","label":"A"},
  {"type":"NUMERIC","name":"b","label":"B"},
  {"type":"NUMERIC","name":"c","label":"C"}
]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"
readstat "$tmpdir/out.dta" >"$tmpdir/summary"

validator_assert_contains "$tmpdir/summary" 'Columns: 3'
