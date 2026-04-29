#!/usr/bin/env bash
# @testcase: usage-readstat-dta-large-positive-number
# @title: readstat DTA large positive number
# @description: Converts a six-digit positive integer to DTA with readstat and verifies the formatted decimal value in the output CSV.
# @timeout: 180
# @tags: usage, csv, readstat
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-readstat-dta-large-positive-number"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
value
123456
CSV
cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"NUMERIC","name":"value","label":"Value"}]}
JSON
readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"
readstat "$tmpdir/out.dta" - >"$tmpdir/out.csv"
validator_assert_contains "$tmpdir/out.csv" '123456.000000'
