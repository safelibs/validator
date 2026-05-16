#!/usr/bin/env bash
# @testcase: usage-readstat-r21-csv-xpt-summary-columns-two
# @title: readstat XPT summary reports Columns: 2 for a two-column CSV input
# @description: Builds a two-column CSV with Stata metadata, converts to .dta then to .xpt, captures the summary, and asserts the literal "Columns: 2" appears - locking in XPT column-count summary specifically (existing XPT tests check rows or single columns).
# @timeout: 60
# @tags: usage, xpt, summary, columns, r21
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
a,b
1,2
3,4
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[
  {"type":"NUMERIC","name":"a","label":"A"},
  {"type":"NUMERIC","name":"b","label":"B"}
]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/mid.dta"
readstat "$tmpdir/mid.dta" "$tmpdir/out.xpt"
readstat "$tmpdir/out.xpt" >"$tmpdir/summary"

validator_assert_contains "$tmpdir/summary" 'Columns: 2'
