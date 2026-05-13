#!/usr/bin/env bash
# @testcase: usage-readstat-r16-csv-comma-in-quoted-cell-survives
# @title: readstat preserves an embedded comma in a quoted string cell through DTA
# @description: Builds a CSV with a comma inside a quoted string field then round-trips it through DTA back to stdout CSV and asserts the recovered text retains the comma in a single quoted cell — verifying the libcsv-backed CSV reader does not split on inner commas.
# @timeout: 60
# @tags: usage, csv, quoting, dta
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
addr,n
"100 Main St, Apt 4",1
"plain",2
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"STRING","name":"addr","label":"Addr"},{"type":"NUMERIC","name":"n","label":"N"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"
readstat "$tmpdir/out.dta" >"$tmpdir/summary"
validator_assert_contains "$tmpdir/summary" 'Rows: 2'
validator_assert_contains "$tmpdir/summary" 'Columns: 2'

readstat "$tmpdir/out.dta" - >"$tmpdir/out.csv"
validator_assert_contains "$tmpdir/out.csv" '"100 Main St, Apt 4"'
