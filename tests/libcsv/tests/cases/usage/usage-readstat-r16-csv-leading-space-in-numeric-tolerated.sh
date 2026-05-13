#!/usr/bin/env bash
# @testcase: usage-readstat-r16-csv-leading-space-in-numeric-tolerated
# @title: readstat tolerates leading whitespace before unquoted numeric cells
# @description: Builds a CSV whose numeric column cells carry one leading space before the digit, converts to DTA, and asserts the .dta summary reports the expected 3 rows and 2 columns — locking in readstat's tolerance for leading whitespace on numeric fields.
# @timeout: 60
# @tags: usage, csv, numeric, whitespace
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<CSV
name,n
alpha, 1
bravo, 2
charlie, 3
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"STRING","name":"name","label":"N"},{"type":"NUMERIC","name":"n","label":"NV"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"
readstat "$tmpdir/out.dta" >"$tmpdir/summary"

validator_assert_contains "$tmpdir/summary" 'Rows: 3'
validator_assert_contains "$tmpdir/summary" 'Columns: 2'
