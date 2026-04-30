#!/usr/bin/env bash
# @testcase: usage-readstat-csv-to-zsav-roundtrip
# @title: readstat CSV to compressed ZSAV round trip
# @description: Converts CSV through DTA into an SPSS compressed binary (ZSAV) file and verifies the values and binary compression marker.
# @timeout: 180
# @tags: usage, csv, zsav
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
name,score
alpha,100
beta,200
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"STRING","name":"name","label":"Name"},{"type":"NUMERIC","name":"score","label":"Score"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/mid.dta"
readstat "$tmpdir/mid.dta" "$tmpdir/out.zsav"
validator_require_file "$tmpdir/out.zsav"

readstat "$tmpdir/out.zsav" - >"$tmpdir/out.csv"
validator_assert_contains "$tmpdir/out.csv" '"name","score"'
validator_assert_contains "$tmpdir/out.csv" '"alpha",100.000000'
validator_assert_contains "$tmpdir/out.csv" '"beta",200.000000'

readstat "$tmpdir/out.zsav" >"$tmpdir/summary"
validator_assert_contains "$tmpdir/summary" 'SPSS compressed binary file (ZSAV)'
validator_assert_contains "$tmpdir/summary" 'Compression: binary'
validator_assert_contains "$tmpdir/summary" 'Columns: 2'
validator_assert_contains "$tmpdir/summary" 'Rows: 2'
