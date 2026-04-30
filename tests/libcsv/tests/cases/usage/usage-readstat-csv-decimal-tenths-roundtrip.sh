#!/usr/bin/env bash
# @testcase: usage-readstat-csv-decimal-tenths-roundtrip
# @title: readstat decimal tenths preserved at six-decimal output
# @description: Converts a CSV whose numeric column carries 0.1, 0.2, and 0.3 through DTA and verifies each value reappears in the readback as its six-decimal short form, confirming tenths round-trip even though they are not exact in binary floating point.
# @timeout: 180
# @tags: usage, csv, decimal, precision
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
name,score
one_tenth,0.1
two_tenths,0.2
three_tenths,0.3
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"STRING","name":"name","label":"Name"},{"type":"NUMERIC","name":"score","label":"Score"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"
readstat "$tmpdir/out.dta" - >"$tmpdir/out.csv"

validator_assert_contains "$tmpdir/out.csv" '"one_tenth",0.100000'
validator_assert_contains "$tmpdir/out.csv" '"two_tenths",0.200000'
validator_assert_contains "$tmpdir/out.csv" '"three_tenths",0.300000'

# None of the tenths should be rendered as long-form 0.099999... or 0.300000000000004.
if grep -E '0\.0999|0\.30000000' "$tmpdir/out.csv" >/dev/null; then
  printf 'tenths rendered with binary floating-point artifacts\n' >&2
  cat "$tmpdir/out.csv" >&2
  exit 1
fi

readstat "$tmpdir/out.dta" >"$tmpdir/summary"
validator_assert_contains "$tmpdir/summary" 'Columns: 2'
validator_assert_contains "$tmpdir/summary" 'Rows: 3'
