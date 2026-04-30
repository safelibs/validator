#!/usr/bin/env bash
# @testcase: usage-readstat-csv-row-column-cell-roundtrip
# @title: readstat specific cell preserved by row and column index
# @description: Builds a CSV where row 4 column 2 carries a unique numeric marker value (8675309) surrounded by distractor zeros, converts through DTA, and verifies the marker reappears at the same row and column position in the readback CSV without bleeding into neighbouring cells.
# @timeout: 180
# @tags: usage, csv, addressing
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
a,b,c
0,0,0
0,0,0
0,0,0
0,8675309,0
0,0,0
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"NUMERIC","name":"a","label":"A"},{"type":"NUMERIC","name":"b","label":"B"},{"type":"NUMERIC","name":"c","label":"C"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"
readstat "$tmpdir/out.dta" - >"$tmpdir/out.csv"

# Header row (line 1) plus 5 data rows: marker is on data row 4, output line 5.
target_line=$(sed -n '5p' "$tmpdir/out.csv")
expected='0.000000,8675309.000000,0.000000'
[[ "$target_line" == "$expected" ]] || {
  printf 'expected %s on line 5, got %s\n' "$expected" "$target_line" >&2
  cat "$tmpdir/out.csv" >&2
  exit 1
}

# Marker must appear exactly once across the entire output.
marker_count=$(grep -c '8675309\.000000' "$tmpdir/out.csv")
[[ "$marker_count" == "1" ]] || {
  printf 'expected marker exactly once, got %s\n' "$marker_count" >&2
  exit 1
}

# Adjacent rows (lines 4 and 6) must remain all-zero.
for ln in 4 6; do
  line=$(sed -n "${ln}p" "$tmpdir/out.csv")
  [[ "$line" == '0.000000,0.000000,0.000000' ]] || {
    printf 'expected all-zero on line %s, got %s\n' "$ln" "$line" >&2
    exit 1
  }
done

readstat "$tmpdir/out.dta" >"$tmpdir/summary"
validator_assert_contains "$tmpdir/summary" 'Columns: 3'
validator_assert_contains "$tmpdir/summary" 'Rows: 5'
