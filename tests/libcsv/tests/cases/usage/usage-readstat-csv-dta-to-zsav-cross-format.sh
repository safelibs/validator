#!/usr/bin/env bash
# @testcase: usage-readstat-csv-dta-to-zsav-cross-format
# @title: readstat converts CSV-built DTA into a ZSAV with binary compression
# @description: Builds a DTA from CSV, then performs a second readstat invocation that consumes the DTA and produces a ZSAV (SPSS compressed) directly without re-using the JSON metadata. Verifies the resulting ZSAV summary reports format "SPSS compressed binary file (ZSAV)", "Compression: binary", "Format version: 3", and that the readback CSV preserves both row values, exercising the DTA-reader -> ZSAV-writer pipeline rather than the CSV-reader pipeline.
# @timeout: 180
# @tags: usage, csv, dta, zsav, cross-format
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
validator_require_file "$tmpdir/mid.dta"

# Direct DTA -> ZSAV: no JSON metadata argument.
readstat "$tmpdir/mid.dta" "$tmpdir/out.zsav"
validator_require_file "$tmpdir/out.zsav"

readstat "$tmpdir/out.zsav" >"$tmpdir/summary"
validator_assert_contains "$tmpdir/summary" 'Format: SPSS compressed binary file (ZSAV)'
validator_assert_contains "$tmpdir/summary" 'Compression: binary'
validator_assert_contains "$tmpdir/summary" 'Format version: 3'
validator_assert_contains "$tmpdir/summary" 'Columns: 2'
validator_assert_contains "$tmpdir/summary" 'Rows: 2'

readstat "$tmpdir/out.zsav" - >"$tmpdir/out.csv"
validator_assert_contains "$tmpdir/out.csv" '"name","score"'
validator_assert_contains "$tmpdir/out.csv" '"alpha",100.000000'
validator_assert_contains "$tmpdir/out.csv" '"beta",200.000000'
