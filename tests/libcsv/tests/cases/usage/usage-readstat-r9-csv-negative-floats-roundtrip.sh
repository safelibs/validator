#!/usr/bin/env bash
# @testcase: usage-readstat-r9-csv-negative-floats-roundtrip
# @title: readstat preserves negative float values
# @description: Roundtrips a CSV containing negative fractional values through DTA and back to CSV, asserting each negative value is preserved with six-decimal formatting.
# @timeout: 180
# @tags: usage, csv, numeric
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
x,y
-1.5,-0.25
-100.5,-0.125
-0.0625,-99.5
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"NUMERIC","name":"x","label":"X"},{"type":"NUMERIC","name":"y","label":"Y"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"
readstat "$tmpdir/out.dta" - >"$tmpdir/out.csv"

validator_assert_contains "$tmpdir/out.csv" '-1.500000,-0.250000'
validator_assert_contains "$tmpdir/out.csv" '-100.500000,-0.125000'
validator_assert_contains "$tmpdir/out.csv" '-0.062500,-99.500000'
