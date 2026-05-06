#!/usr/bin/env bash
# @testcase: usage-readstat-r10-csv-extreme-double-precision-preserved
# @title: readstat preserves a 14-significant-digit double through DTA roundtrip
# @description: Round-trips two well-known irrational constants with at least 15 input digits (pi 3.141592653589793, sqrt2 1.4142135623730951) through DTA and back to CSV and verifies the readstat CSV writer emits the values with the high-precision 14-significant-digit rendering that occurs whenever the truncation to the default 6-decimal form would lose information.
# @timeout: 120
# @tags: usage, csv, double, precision
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
constant,value
pi,3.141592653589793
sqrt2,1.4142135623730951
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"STRING","name":"constant","label":"C"},{"type":"NUMERIC","name":"value","label":"V"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"
readstat "$tmpdir/out.dta" - >"$tmpdir/out.csv"

# Header preserved.
validator_assert_contains "$tmpdir/out.csv" '"constant","value"'

# Pi must reappear with the high-precision rendering, NOT the 6-decimal form.
validator_assert_contains "$tmpdir/out.csv" '3.14159265358979'
if grep -F '3.141593' "$tmpdir/out.csv" >/dev/null; then
  printf 'pi value was truncated to 6 decimals, losing precision\n' >&2
  cat "$tmpdir/out.csv" >&2
  exit 1
fi

# sqrt(2) must reappear with the high-precision rendering as well.
validator_assert_contains "$tmpdir/out.csv" '1.4142135623731'
if grep -F '1.414214' "$tmpdir/out.csv" >/dev/null; then
  printf 'sqrt(2) value was truncated to 6 decimals, losing precision\n' >&2
  cat "$tmpdir/out.csv" >&2
  exit 1
fi
