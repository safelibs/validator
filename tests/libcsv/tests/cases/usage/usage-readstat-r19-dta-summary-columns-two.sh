#!/usr/bin/env bash
# @testcase: usage-readstat-r19-dta-summary-columns-two
# @title: readstat summary of a two-column DTA reports Columns: 2
# @description: Builds a two-column CSV with three rows, converts to .dta, captures the summary, and asserts it contains the literal token "Columns: 2" - locking in the column-count line of the DTA summary for the exact two-column case.
# @timeout: 60
# @tags: usage, csv, dta, summary, columns, r19
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
left,right
10,20
30,40
50,60
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"NUMERIC","name":"left","label":"L"},{"type":"NUMERIC","name":"right","label":"R"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"
readstat "$tmpdir/out.dta" >"$tmpdir/summary"

validator_assert_contains "$tmpdir/summary" 'Columns: 2'
