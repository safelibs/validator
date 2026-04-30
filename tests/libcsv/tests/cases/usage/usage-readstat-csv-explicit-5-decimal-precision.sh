#!/usr/bin/env bash
# @testcase: usage-readstat-csv-explicit-5-decimal-precision
# @title: readstat CSV with explicit 5-decimal-place precision values
# @description: Builds a CSV whose numeric column carries values written with exactly five decimal places (0.12345, 1.23456, 9.87654), converts through DTA, and verifies the readback emits each value in readstat's six-decimal short form with the original five-decimal digits intact and a trailing zero appended, demonstrating that the input precision is preserved without rounding away significant digits.
# @timeout: 180
# @tags: usage, csv, precision, decimal
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Each value has exactly 5 decimal places (sub-six-decimal so no rounding applies).
cat >"$tmpdir/in.csv" <<'CSV'
name,score
alpha,0.12345
beta,1.23456
gamma,9.87654
delta,0.00001
epsilon,2.50000
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"STRING","name":"name","label":"Name"},{"type":"NUMERIC","name":"score","label":"Score"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"
validator_require_file "$tmpdir/out.dta"

readstat "$tmpdir/out.dta" - >"$tmpdir/out.csv"

# Five-decimal inputs render in six-decimal short form by trailing-zero extension.
validator_assert_contains "$tmpdir/out.csv" '"alpha",0.123450'
validator_assert_contains "$tmpdir/out.csv" '"beta",1.234560'
validator_assert_contains "$tmpdir/out.csv" '"gamma",9.876540'
validator_assert_contains "$tmpdir/out.csv" '"delta",0.000010'
validator_assert_contains "$tmpdir/out.csv" '"epsilon",2.500000'

# No value should appear truncated to four decimals or less.
for needle in '"alpha",0.1234,' '"beta",1.2345,' '"gamma",9.8765,'; do
  if grep -F -- "$needle" "$tmpdir/out.csv" >/dev/null; then
    printf 'value truncated below input precision: %s\n' "$needle" >&2
    cat "$tmpdir/out.csv" >&2
    exit 1
  fi
done

# Every numeric cell must match the exact six-decimal pattern.
for ln in 2 3 4 5 6; do
  cell=$(sed -n "${ln}p" "$tmpdir/out.csv" | cut -d, -f2)
  if ! [[ "$cell" =~ ^[0-9]+\.[0-9]{6}$ ]]; then
    printf 'line %s numeric cell does not match six-decimal pattern: %s\n' "$ln" "$cell" >&2
    exit 1
  fi
done

readstat "$tmpdir/out.dta" >"$tmpdir/summary"
validator_assert_contains "$tmpdir/summary" 'Columns: 2'
validator_assert_contains "$tmpdir/summary" 'Rows: 5'
