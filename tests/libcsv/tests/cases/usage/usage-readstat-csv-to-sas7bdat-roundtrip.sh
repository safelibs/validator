#!/usr/bin/env bash
# @testcase: usage-readstat-csv-to-sas7bdat-roundtrip
# @title: readstat CSV to SAS7BDAT round trip
# @description: Converts CSV through DTA into a SAS7BDAT data file and verifies the field values reappear in CSV after readback.
# @timeout: 180
# @tags: usage, csv, sas7bdat
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
name,score
alpha,1
beta,2
gamma,3
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"STRING","name":"name","label":"Name"},{"type":"NUMERIC","name":"score","label":"Score"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/mid.dta"
readstat "$tmpdir/mid.dta" "$tmpdir/out.sas7bdat"
validator_require_file "$tmpdir/out.sas7bdat"

readstat "$tmpdir/out.sas7bdat" - >"$tmpdir/out.csv"
validator_assert_contains "$tmpdir/out.csv" '"name","score"'
validator_assert_contains "$tmpdir/out.csv" '"alpha",1.000000'
validator_assert_contains "$tmpdir/out.csv" '"beta",2.000000'
validator_assert_contains "$tmpdir/out.csv" '"gamma",3.000000'

readstat "$tmpdir/out.sas7bdat" >"$tmpdir/summary"
validator_assert_contains "$tmpdir/summary" 'SAS data file (SAS7BDAT)'
validator_assert_contains "$tmpdir/summary" 'Columns: 2'
validator_assert_contains "$tmpdir/summary" 'Rows: 3'
