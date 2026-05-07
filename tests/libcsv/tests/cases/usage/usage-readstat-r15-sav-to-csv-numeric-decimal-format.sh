#!/usr/bin/env bash
# @testcase: usage-readstat-r15-sav-to-csv-numeric-decimal-format
# @title: readstat sav-to-csv renders numeric integers as 6-decimal floating-point literals
# @description: Round-trips a 2-row CSV (with integer-looking numeric values) through DTA into SAV and back to CSV, and asserts the body contains the literal "1.000000" and "2.000000" forms — locking in that the SAV read path renders numeric fields with six decimal places by default on Ubuntu 24.04 readstat 1.1.9, matching the XPT and SAS7BDAT six-decimal rendering tests already in r11.
# @timeout: 120
# @tags: usage, csv, sav, decimal-format
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
id
1
2
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"NUMERIC","name":"id","label":"ID"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/mid.dta"
readstat "$tmpdir/mid.dta" "$tmpdir/out.sav"
readstat "$tmpdir/out.sav" - >"$tmpdir/out.csv"

validator_assert_contains "$tmpdir/out.csv" '1.000000'
validator_assert_contains "$tmpdir/out.csv" '2.000000'
