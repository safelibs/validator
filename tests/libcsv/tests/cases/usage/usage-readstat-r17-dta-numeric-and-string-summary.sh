#!/usr/bin/env bash
# @testcase: usage-readstat-r17-dta-numeric-and-string-summary
# @title: readstat .dta summary names a numeric column and a string column distinctly
# @description: Builds a .dta with one NUMERIC and one STRING variable from a small CSV and asserts the summary lists both column names — locking in mixed-type variable enumeration without depending on row counts that have been flaky on larger inputs.
# @timeout: 60
# @tags: usage, csv, dta, mixed
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
score,name
10,alpha
20,bravo
30,charlie
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"NUMERIC","name":"score","label":"Score"},{"type":"STRING","name":"name","label":"Name"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"
readstat "$tmpdir/out.dta" >"$tmpdir/summary"

validator_assert_contains "$tmpdir/summary" 'score'
validator_assert_contains "$tmpdir/summary" 'name'
