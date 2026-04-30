#!/usr/bin/env bash
# @testcase: usage-readstat-csv-5000-rows
# @title: readstat 5000 row CSV summary
# @description: Builds a 5000-row numeric CSV, converts it through DTA, and verifies the summary reports the exact row count and that the first and last data rows survive readback.
# @timeout: 300
# @tags: usage, csv, scale
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir" <<'PY'
import os, sys
out = sys.argv[1]
n = 5000
with open(os.path.join(out, "in.csv"), "w") as f:
    f.write("idx,score\n")
    for i in range(n):
        f.write(f"{i},{i*2}\n")
PY

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"NUMERIC","name":"idx","label":"Index"},{"type":"NUMERIC","name":"score","label":"Score"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"

readstat "$tmpdir/out.dta" >"$tmpdir/summary"
validator_assert_contains "$tmpdir/summary" 'Columns: 2'
validator_assert_contains "$tmpdir/summary" 'Rows: 5000'

readstat "$tmpdir/out.dta" - >"$tmpdir/out.csv"

# Header + 5000 data rows = 5001 lines.
total=$(wc -l <"$tmpdir/out.csv")
[[ "$total" == "5001" ]] || {
  printf 'expected 5001 output lines, got %s\n' "$total" >&2
  exit 1
}

# First data row: idx=0, score=0.
first=$(sed -n '2p' "$tmpdir/out.csv")
[[ "$first" == "0.000000,0.000000" ]] || {
  printf 'first row mismatch: %s\n' "$first" >&2
  exit 1
}

# Last data row: idx=4999, score=9998.
last=$(sed -n '5001p' "$tmpdir/out.csv")
[[ "$last" == "4999.000000,9998.000000" ]] || {
  printf 'last row mismatch: %s\n' "$last" >&2
  exit 1
}
