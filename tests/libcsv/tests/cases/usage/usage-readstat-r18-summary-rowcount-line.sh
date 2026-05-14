#!/usr/bin/env bash
# @testcase: usage-readstat-r18-summary-rowcount-line
# @title: readstat summary reports the exact Rows count for a four-row input
# @description: Converts a CSV with exactly four data rows to .dta then captures the summary by invoking readstat against the .dta with no output destination, and asserts the summary contains "Rows: 4" — locking in row-count summary emission for known cardinality.
# @timeout: 60
# @tags: usage, csv, dta, summary, r18
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
a,b
1,2
3,4
5,6
7,8
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"NUMERIC","name":"a","label":"A"},{"type":"NUMERIC","name":"b","label":"B"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"
readstat "$tmpdir/out.dta" >"$tmpdir/summary"

validator_assert_contains "$tmpdir/summary" 'Rows: 4'
validator_assert_contains "$tmpdir/summary" 'Columns: 2'
