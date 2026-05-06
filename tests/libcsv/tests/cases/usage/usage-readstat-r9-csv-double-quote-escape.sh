#!/usr/bin/env bash
# @testcase: usage-readstat-r9-csv-double-quote-escape
# @title: readstat handles doubled-quote escape
# @description: Provides a CSV cell containing an escaped double-quote ("") and confirms readstat parses the row as a single quoted field whose value contains a literal double quote.
# @timeout: 180
# @tags: usage, csv, escaping
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
text
"she said ""hi"" loudly"
"plain"
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"STRING","name":"text","label":"T"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"
readstat "$tmpdir/out.dta" >"$tmpdir/summary"
validator_assert_contains "$tmpdir/summary" 'Columns: 1'
validator_assert_contains "$tmpdir/summary" 'Rows: 2'

readstat "$tmpdir/out.dta" - >"$tmpdir/out.csv"
# The doubled-quote should be preserved as a literal " in the rendered output.
grep -F 'she said' "$tmpdir/out.csv" >"$tmpdir/match"
[[ -s "$tmpdir/match" ]]
