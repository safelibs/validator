#!/usr/bin/env bash
# @testcase: usage-readstat-csv-leading-plus-sign
# @title: readstat numeric with leading plus sign
# @description: Converts a CSV whose numeric values carry an explicit leading plus sign through DTA and verifies the sign is normalized away in the readback.
# @timeout: 180
# @tags: usage, csv, numeric
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
name,score
plus_int,+42
plus_dec,+3.14
plus_zero,+0
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"STRING","name":"name","label":"Name"},{"type":"NUMERIC","name":"score","label":"Score"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"
readstat "$tmpdir/out.dta" - >"$tmpdir/out.csv"

validator_assert_contains "$tmpdir/out.csv" '"plus_int",42.000000'
validator_assert_contains "$tmpdir/out.csv" '"plus_dec",3.140000'
validator_assert_contains "$tmpdir/out.csv" '"plus_zero",0.000000'

# The literal '+' must not survive into the CSV output.
if grep -F '+' "$tmpdir/out.csv" >/dev/null; then
  printf 'unexpected plus sign in normalized output\n' >&2
  cat "$tmpdir/out.csv" >&2
  exit 1
fi

readstat "$tmpdir/out.dta" >"$tmpdir/summary"
validator_assert_contains "$tmpdir/summary" 'Rows: 3'
