#!/usr/bin/env bash
# @testcase: usage-readstat-csv-many-distinct-increasing
# @title: readstat distinct strictly increasing numeric column preserves order and values
# @description: Builds a CSV with one numeric column carrying 25 strictly increasing distinct values, converts through DTA, and verifies every value reappears at its original line position so neither the order nor the magnitudes drift after the round trip.
# @timeout: 180
# @tags: usage, csv, numeric, ordering
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir" <<'PY'
import os, sys
out = sys.argv[1]
# 25 strictly increasing values, deliberately not a simple arithmetic step.
values = [3, 7, 11, 18, 25, 34, 48, 59, 67, 80,
          93, 105, 121, 134, 150, 169, 188, 206, 227, 248,
          271, 295, 320, 346, 373]
with open(os.path.join(out, "in.csv"), "w") as f:
    f.write("value\n")
    for v in values:
        f.write(f"{v}\n")
with open(os.path.join(out, "expected.txt"), "w") as f:
    for v in values:
        f.write(f"{v}.000000\n")
PY

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"NUMERIC","name":"value","label":"Value"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"
readstat "$tmpdir/out.dta" - >"$tmpdir/out.csv"

# Header preserved.
header=$(sed -n '1p' "$tmpdir/out.csv")
[[ "$header" == '"value"' ]] || {
  printf 'unexpected header: %s\n' "$header" >&2
  exit 1
}

# Each expected value must appear on the matching output line so order is locked.
mapfile -t expected <"$tmpdir/expected.txt"
for idx in "${!expected[@]}"; do
  line_no=$((idx + 2))
  actual=$(sed -n "${line_no}p" "$tmpdir/out.csv")
  [[ "$actual" == "${expected[$idx]}" ]] || {
    printf 'line %s mismatch: expected %s, got %s\n' "$line_no" "${expected[$idx]}" "$actual" >&2
    cat "$tmpdir/out.csv" >&2
    exit 1
  }
done

# Strict monotonic increase across the readback (cross-check on floats).
python3 - "$tmpdir/out.csv" <<'PY'
import csv, sys
with open(sys.argv[1], newline="") as f:
    rows = list(csv.reader(f))
nums = [float(r[0]) for r in rows[1:] if r]
if len(nums) != 25:
    sys.stderr.write(f"expected 25 data rows, got {len(nums)}\n")
    sys.exit(1)
for a, b in zip(nums, nums[1:]):
    if not (a < b):
        sys.stderr.write(f"non-increasing pair: {a} >= {b}\n")
        sys.exit(1)
PY

readstat "$tmpdir/out.dta" >"$tmpdir/summary"
validator_assert_contains "$tmpdir/summary" 'Columns: 1'
validator_assert_contains "$tmpdir/summary" 'Rows: 25'
