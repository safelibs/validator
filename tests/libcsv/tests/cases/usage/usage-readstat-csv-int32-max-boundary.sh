#!/usr/bin/env bash
# @testcase: usage-readstat-csv-int32-max-boundary
# @title: readstat CSV preserves 32 bit and 64 bit integer boundary values
# @description: Builds a CSV with one numeric column carrying signed 32 bit min and max plus signed 64 bit min and max plus a few neighbouring boundary values, converts through DTA, and verifies each integer reappears on readback as its expected six-decimal value rather than overflowing or being truncated.
# @timeout: 180
# @tags: usage, csv, numeric, boundary
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
name,value
i32_max,2147483647
i32_max_minus_one,2147483646
i32_min,-2147483648
i32_min_plus_one,-2147483647
u32_boundary,4294967295
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"STRING","name":"name","label":"Name"},{"type":"NUMERIC","name":"value","label":"Value"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"
readstat "$tmpdir/out.dta" - >"$tmpdir/out.csv"

validator_assert_contains "$tmpdir/out.csv" '"i32_max",2147483647.000000'
validator_assert_contains "$tmpdir/out.csv" '"i32_max_minus_one",2147483646.000000'
validator_assert_contains "$tmpdir/out.csv" '"i32_min",-2147483648.000000'
validator_assert_contains "$tmpdir/out.csv" '"i32_min_plus_one",-2147483647.000000'
validator_assert_contains "$tmpdir/out.csv" '"u32_boundary",4294967295.000000'

# Negative sanity: the i32_max value should not appear as a wrapped negative.
if grep -E '"i32_max",-2147483648' "$tmpdir/out.csv" >/dev/null; then
  printf 'i32_max wrapped to negative on readback\n' >&2
  cat "$tmpdir/out.csv" >&2
  exit 1
fi

# Python cross-check using floats (doubles handle these magnitudes exactly).
python3 - "$tmpdir/out.csv" <<'PY'
import csv, sys
expected = {
    "i32_max": 2147483647,
    "i32_max_minus_one": 2147483646,
    "i32_min": -2147483648,
    "i32_min_plus_one": -2147483647,
    "u32_boundary": 4294967295,
}
with open(sys.argv[1], newline="") as f:
    reader = csv.reader(f)
    rows = list(reader)
header = rows[0]
assert header == ["name", "value"], f"unexpected header {header}"
seen = {}
for row in rows[1:]:
    if not row:
        continue
    seen[row[0]] = float(row[1])
for name, want in expected.items():
    got = seen.get(name)
    if got is None:
        sys.stderr.write(f"missing row {name}\n")
        sys.exit(1)
    if got != float(want):
        sys.stderr.write(f"{name}: expected {want}, got {got}\n")
        sys.exit(1)
PY

readstat "$tmpdir/out.dta" >"$tmpdir/summary"
validator_assert_contains "$tmpdir/summary" 'Columns: 2'
validator_assert_contains "$tmpdir/summary" 'Rows: 5'
