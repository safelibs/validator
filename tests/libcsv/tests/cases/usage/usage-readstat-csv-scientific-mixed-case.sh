#!/usr/bin/env bash
# @testcase: usage-readstat-csv-scientific-mixed-case
# @title: readstat scientific notation lowercase and uppercase
# @description: Converts a CSV with scientific notation values using both lowercase e and uppercase E, plus negative exponents, through DTA and verifies each parses to the expected numeric value.
# @timeout: 180
# @tags: usage, csv, numeric
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
name,score
lower_pos,1.5e3
upper_pos,2.5E4
lower_neg,4e-3
upper_neg,7.5E-2
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"STRING","name":"name","label":"Name"},{"type":"NUMERIC","name":"score","label":"Score"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"
readstat "$tmpdir/out.dta" - >"$tmpdir/out.csv"

# 1.5e3 = 1500, 2.5E4 = 25000, 4e-3 = 0.004, 7.5E-2 = 0.075.
validator_assert_contains "$tmpdir/out.csv" '"lower_pos",1500.000000'
validator_assert_contains "$tmpdir/out.csv" '"upper_pos",25000.000000'
validator_assert_contains "$tmpdir/out.csv" '"lower_neg",0.004000'
validator_assert_contains "$tmpdir/out.csv" '"upper_neg",0.075000'

# No leftover scientific 'e'/'E' in the canonical output.
if grep -E '[eE][+-]?[0-9]' "$tmpdir/out.csv" >/dev/null; then
  printf 'expected fixed-point output, found scientific notation\n' >&2
  cat "$tmpdir/out.csv" >&2
  exit 1
fi
