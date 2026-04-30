#!/usr/bin/env bash
# @testcase: usage-readstat-csv-float-half-step
# @title: readstat single float column 0.5 step roundtrip
# @description: Builds a CSV with one numeric column ranging from 0.5 to 50.0 in 0.5 steps, converts through DTA, and verifies the row count and the first, last, and a midpoint value all survive readback.
# @timeout: 180
# @tags: usage, csv, decimal
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir" <<'PY'
import os, sys
out = sys.argv[1]
with open(os.path.join(out, "in.csv"), "w") as f:
    f.write("x\n")
    # 0.5, 1.0, 1.5, ..., 50.0 -> 100 values.
    for i in range(1, 101):
        f.write(f"{i*0.5}\n")
PY

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"NUMERIC","name":"x","label":"X"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"

readstat "$tmpdir/out.dta" >"$tmpdir/summary"
validator_assert_contains "$tmpdir/summary" 'Columns: 1'
validator_assert_contains "$tmpdir/summary" 'Rows: 100'

readstat "$tmpdir/out.dta" - >"$tmpdir/out.csv"

# Header + 100 rows.
total=$(wc -l <"$tmpdir/out.csv")
[[ "$total" == "101" ]] || {
  printf 'expected 101 lines, got %s\n' "$total" >&2
  exit 1
}

# First data row: 0.5.
first=$(sed -n '2p' "$tmpdir/out.csv")
[[ "$first" == "0.500000" ]] || {
  printf 'first row mismatch: %s\n' "$first" >&2
  exit 1
}

# Last data row: 50.0.
last=$(sed -n '101p' "$tmpdir/out.csv")
[[ "$last" == "50.000000" ]] || {
  printf 'last row mismatch: %s\n' "$last" >&2
  exit 1
}

# Midpoint: data row 50 (line 51) -> 25.0.
mid=$(sed -n '51p' "$tmpdir/out.csv")
[[ "$mid" == "25.000000" ]] || {
  printf 'midpoint row mismatch: %s\n' "$mid" >&2
  exit 1
}
