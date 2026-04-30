#!/usr/bin/env bash
# @testcase: usage-readstat-csv-int-1-to-1000-count
# @title: readstat single int column 1 to 1000 count
# @description: Builds a CSV with a single numeric column carrying integers 1 through 1000, converts through DTA, and verifies the summary reports exactly 1000 rows and that the first and last values reappear at the expected positions.
# @timeout: 240
# @tags: usage, csv, scale
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir" <<'PY'
import os, sys
out = sys.argv[1]
with open(os.path.join(out, "in.csv"), "w") as f:
    f.write("v\n")
    for i in range(1, 1001):
        f.write(f"{i}\n")
PY

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"NUMERIC","name":"v","label":"Value"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"

readstat "$tmpdir/out.dta" >"$tmpdir/summary"
validator_assert_contains "$tmpdir/summary" 'Columns: 1'
validator_assert_contains "$tmpdir/summary" 'Rows: 1000'

readstat "$tmpdir/out.dta" - >"$tmpdir/out.csv"

# Header + 1000 data rows.
total=$(wc -l <"$tmpdir/out.csv")
[[ "$total" == "1001" ]] || {
  printf 'expected 1001 lines, got %s\n' "$total" >&2
  exit 1
}

first=$(sed -n '2p' "$tmpdir/out.csv")
[[ "$first" == "1.000000" ]] || {
  printf 'first row mismatch: %s\n' "$first" >&2
  exit 1
}

last=$(sed -n '1001p' "$tmpdir/out.csv")
[[ "$last" == "1000.000000" ]] || {
  printf 'last row mismatch: %s\n' "$last" >&2
  exit 1
}

# Spot-check a midpoint row: line 501 (data row 500) -> value 500.
mid=$(sed -n '501p' "$tmpdir/out.csv")
[[ "$mid" == "500.000000" ]] || {
  printf 'midpoint row mismatch: %s\n' "$mid" >&2
  exit 1
}
