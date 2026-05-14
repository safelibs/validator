#!/usr/bin/env bash
# @testcase: usage-readstat-r18-three-column-summary-shape
# @title: readstat summary of a three-column DTA reports Columns 3 and matching Rows
# @description: Builds a three-column CSV with three data rows, converts to .dta, captures the summary, and asserts the summary contains both "Columns: 3" and "Rows: 3" — locking in the shape report for an explicitly multi-column input.
# @timeout: 60
# @tags: usage, csv, dta, summary, shape, r18
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
a,b,c
1,2,3
4,5,6
7,8,9
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"NUMERIC","name":"a","label":"A"},{"type":"NUMERIC","name":"b","label":"B"},{"type":"NUMERIC","name":"c","label":"C"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"
readstat "$tmpdir/out.dta" >"$tmpdir/summary"

validator_assert_contains "$tmpdir/summary" 'Columns: 3'
validator_assert_contains "$tmpdir/summary" 'Rows: 3'
