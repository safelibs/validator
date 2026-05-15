#!/usr/bin/env bash
# @testcase: usage-readstat-r20-csv-sas7bdat-summary-rows
# @title: readstat summary of a four-row SAS7BDAT (via DTA) reports Rows: 4
# @description: Builds a four-row CSV, converts to .dta via Stata metadata, converts the .dta to .sas7bdat, then captures the summary output and asserts it contains the literal "Rows: 4" - locking in row-count reporting on the SAS7BDAT writer/reader path.
# @timeout: 60
# @tags: usage, csv, sas7bdat, summary, rows, r20
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
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"NUMERIC","name":"v","label":"V"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/mid.dta"
readstat "$tmpdir/mid.dta" "$tmpdir/out.sas7bdat"
readstat "$tmpdir/out.sas7bdat" >"$tmpdir/summary"

validator_assert_contains "$tmpdir/summary" 'Rows: 4'
