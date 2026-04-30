#!/usr/bin/env bash
# @testcase: usage-readstat-csv-numeric-precision
# @title: readstat numeric precision through DTA
# @description: Converts a CSV with several many-digit decimal values through DTA and verifies the readback retains 15 significant digits, matching readstat's high-precision numeric output.
# @timeout: 180
# @tags: usage, csv, precision
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Inputs chosen so each value has more than 15 significant digits in CSV.
cat >"$tmpdir/in.csv" <<'CSV'
name,score
pi,3.141592653589793
e,2.718281828459045
sqrt2,1.414213562373095
neg_third,-0.333333333333333
quarter,0.25
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"STRING","name":"name","label":"Name"},{"type":"NUMERIC","name":"score","label":"Score"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"
readstat "$tmpdir/out.dta" - >"$tmpdir/out.csv"

# readstat preserves the round-trippable 15-significant-digit double representation.
validator_assert_contains "$tmpdir/out.csv" '"pi",3.14159265358979'
validator_assert_contains "$tmpdir/out.csv" '"e",2.71828182845905'
validator_assert_contains "$tmpdir/out.csv" '"sqrt2",1.41421356237309'
validator_assert_contains "$tmpdir/out.csv" '"neg_third",-0.33333333333333'
# Exact terminating decimals retain the six-decimal short form.
validator_assert_contains "$tmpdir/out.csv" '"quarter",0.250000'

readstat "$tmpdir/out.dta" >"$tmpdir/summary"
validator_assert_contains "$tmpdir/summary" 'Rows: 5'
