#!/usr/bin/env bash
# @testcase: usage-readstat-csv-multi-negative-numbers
# @title: readstat multiple negative numeric rows
# @description: Converts a CSV with several negative numeric values of varying magnitudes through DTA and verifies each value reappears in the CSV readback.
# @timeout: 180
# @tags: usage, csv, numeric
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
name,score
small,-1
medium,-1234
large,-9876543
fractional,-0.5
mixed,-0.0001
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"STRING","name":"name","label":"Name"},{"type":"NUMERIC","name":"score","label":"Score"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"
readstat "$tmpdir/out.dta" - >"$tmpdir/out.csv"

validator_assert_contains "$tmpdir/out.csv" '"small",-1.000000'
validator_assert_contains "$tmpdir/out.csv" '"medium",-1234.000000'
validator_assert_contains "$tmpdir/out.csv" '"large",-9876543.000000'
validator_assert_contains "$tmpdir/out.csv" '"fractional",-0.500000'
validator_assert_contains "$tmpdir/out.csv" '"mixed",-0.000100'

# No accidental positive sign for any of the rows.
if grep -E '^"(small|medium|large|fractional|mixed)",[0-9]' "$tmpdir/out.csv" >/dev/null; then
  printf 'unexpected positive value in negative-only column\n' >&2
  cat "$tmpdir/out.csv" >&2
  exit 1
fi

readstat "$tmpdir/out.dta" >"$tmpdir/summary"
validator_assert_contains "$tmpdir/summary" 'Rows: 5'
