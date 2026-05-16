#!/usr/bin/env bash
# @testcase: usage-readstat-r21-csv-mixed-types-survive-roundtrip
# @title: readstat CSV with one numeric and one string column preserved through DTA
# @description: Builds a 3-row CSV with a numeric column and a string column, converts through .dta and back to stdout CSV, and asserts both columns' values appear in the recovered output - locking in mixed-type-column roundtrip behavior at 3 rows distinct from existing one-numeric-one-string and r9-mixed tests by checking specific token presence in both columns.
# @timeout: 60
# @tags: usage, csv, dta, mixed-types, r21
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
num,word
11,foxtrot
22,golf
33,hotel
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[
  {"type":"NUMERIC","name":"num","label":"Num"},
  {"type":"STRING","name":"word","label":"Word"}
]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/mid.dta"
readstat "$tmpdir/mid.dta" - >"$tmpdir/out.csv"

for tok in foxtrot golf hotel; do
    validator_assert_contains "$tmpdir/out.csv" "$tok"
done
# Numeric values survive as well
for v in 11 22 33; do
    validator_assert_contains "$tmpdir/out.csv" "$v"
done
