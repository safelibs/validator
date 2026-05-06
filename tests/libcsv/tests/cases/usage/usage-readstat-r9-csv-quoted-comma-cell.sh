#!/usr/bin/env bash
# @testcase: usage-readstat-r9-csv-quoted-comma-cell
# @title: readstat preserves quoted comma cell
# @description: Embeds a literal comma inside a quoted CSV cell and verifies readstat keeps the field as a single column without splitting on the inner comma.
# @timeout: 180
# @tags: usage, csv, quoting
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
label,n
"hello, world",1
"a,b,c",2
"plain",3
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"STRING","name":"label","label":"L"},{"type":"NUMERIC","name":"n","label":"N"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"
readstat "$tmpdir/out.dta" >"$tmpdir/summary"
validator_assert_contains "$tmpdir/summary" 'Columns: 2'
validator_assert_contains "$tmpdir/summary" 'Rows: 3'

readstat "$tmpdir/out.dta" - >"$tmpdir/out.csv"
validator_assert_contains "$tmpdir/out.csv" '"hello, world"'
validator_assert_contains "$tmpdir/out.csv" '"a,b,c"'
