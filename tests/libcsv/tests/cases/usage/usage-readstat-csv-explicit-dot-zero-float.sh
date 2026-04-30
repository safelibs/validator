#!/usr/bin/env bash
# @testcase: usage-readstat-csv-explicit-dot-zero-float
# @title: readstat numeric column with explicit .0 suffix preserved as float
# @description: Builds a CSV whose numeric column carries values written with an explicit .0 decimal suffix (rather than bare integers), converts through DTA, and verifies the readback always renders six-decimal floats so the values are interpreted as numeric rather than as a string column even though they look integer-valued.
# @timeout: 180
# @tags: usage, csv, decimal, numeric
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
name,score
zero,0.0
one,1.0
two,2.0
ten,10.0
hundred,100.0
neg_one,-1.0
neg_ten,-10.0
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"STRING","name":"name","label":"Name"},{"type":"NUMERIC","name":"score","label":"Score"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"
readstat "$tmpdir/out.dta" - >"$tmpdir/out.csv"

validator_assert_contains "$tmpdir/out.csv" '"zero",0.000000'
validator_assert_contains "$tmpdir/out.csv" '"one",1.000000'
validator_assert_contains "$tmpdir/out.csv" '"two",2.000000'
validator_assert_contains "$tmpdir/out.csv" '"ten",10.000000'
validator_assert_contains "$tmpdir/out.csv" '"hundred",100.000000'
validator_assert_contains "$tmpdir/out.csv" '"neg_one",-1.000000'
validator_assert_contains "$tmpdir/out.csv" '"neg_ten",-10.000000'

# The score column must not be quoted (which would mark it as a string column).
if grep -E '"(zero|one|two)","[0-9.]+"' "$tmpdir/out.csv" >/dev/null; then
  printf 'numeric values with .0 suffix were stored as strings\n' >&2
  cat "$tmpdir/out.csv" >&2
  exit 1
fi

# And the readback must use six-decimal float rendering, never bare ints.
if grep -E '^"[a-z_]+",-?[0-9]+$' "$tmpdir/out.csv" >/dev/null; then
  printf 'expected six-decimal float rendering, got bare integer\n' >&2
  cat "$tmpdir/out.csv" >&2
  exit 1
fi

readstat "$tmpdir/out.dta" >"$tmpdir/summary"
validator_assert_contains "$tmpdir/summary" 'Columns: 2'
validator_assert_contains "$tmpdir/summary" 'Rows: 7'
