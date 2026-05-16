#!/usr/bin/env bash
# @testcase: usage-readstat-r21-csv-zsav-rowcount-summary
# @title: readstat summary of a six-row ZSAV reports Rows: 6
# @description: Builds a six-row CSV, converts to .dta then to .zsav, captures the summary, and asserts the literal "Rows: 6" appears - locking in compressed SAV row-count summary on a non-zero non-{3,5} row count (existing zsav tests cover 3-row and 5-row counts).
# @timeout: 60
# @tags: usage, zsav, summary, rows, r21
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
v
10
20
30
40
50
60
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"NUMERIC","name":"v","label":"V"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/mid.dta"
readstat "$tmpdir/mid.dta" "$tmpdir/out.zsav"
readstat "$tmpdir/out.zsav" >"$tmpdir/summary"

validator_assert_contains "$tmpdir/summary" 'Rows: 6'
