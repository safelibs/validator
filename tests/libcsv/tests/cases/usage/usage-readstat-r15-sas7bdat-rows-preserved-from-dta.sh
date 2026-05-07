#!/usr/bin/env bash
# @testcase: usage-readstat-r15-sas7bdat-rows-preserved-from-dta
# @title: readstat dta-to-sas7bdat preserves the precise row count across the conversion
# @description: Builds a 4-row DTA from a CSV and converts it to SAS7BDAT, then asserts the SAS7BDAT readstat summary reports "Rows: 4" — locking in that the SAS7BDAT writer preserves the exact source row count when the input is a DTA on Ubuntu 24.04 readstat 1.1.9, complementary to the existing csv-to-sas7bdat magic and version tests.
# @timeout: 120
# @tags: usage, csv, sas7bdat, roundtrip, rows
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
id,score
1,10
2,20
3,30
4,40
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"NUMERIC","name":"id","label":"ID"},{"type":"NUMERIC","name":"score","label":"Score"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/mid.dta"
readstat "$tmpdir/mid.dta" "$tmpdir/out.sas7bdat"
readstat "$tmpdir/out.sas7bdat" >"$tmpdir/summary"

validator_assert_contains "$tmpdir/summary" 'Format: SAS data file (SAS7BDAT)'
grep -E '^Rows: 4$' "$tmpdir/summary" >/dev/null || {
  printf 'SAS7BDAT summary did not pin Rows to 4\n' >&2
  cat "$tmpdir/summary" >&2
  exit 1
}
