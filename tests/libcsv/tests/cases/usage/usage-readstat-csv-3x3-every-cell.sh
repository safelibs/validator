#!/usr/bin/env bash
# @testcase: usage-readstat-csv-3x3-every-cell
# @title: readstat 3x3 CSV every cell verified after DTA round trip
# @description: Builds a small three-row by three-column CSV with distinct values in every cell so each one is uniquely addressable, converts through DTA, and verifies each of the nine cells reappears at the matching row and column position on readback so no row or column gets transposed, dropped, or duplicated.
# @timeout: 180
# @tags: usage, csv, addressing, mixed
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
label,score,note
r1,11,first
r2,22,second
r3,33,third
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"STRING","name":"label","label":"Label"},{"type":"NUMERIC","name":"score","label":"Score"},{"type":"STRING","name":"note","label":"Note"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"
readstat "$tmpdir/out.dta" - >"$tmpdir/out.csv"

# Header must agree with the input order.
header=$(sed -n '1p' "$tmpdir/out.csv")
[[ "$header" == '"label","score","note"' ]] || {
  printf 'unexpected header: %s\n' "$header" >&2
  exit 1
}

# Address every one of the nine data cells by exact line equality so a
# transposed row or shuffled column would fail loudly.
declare -A expected=(
  [2]='"r1",11.000000,"first"'
  [3]='"r2",22.000000,"second"'
  [4]='"r3",33.000000,"third"'
)
for ln in 2 3 4; do
  actual=$(sed -n "${ln}p" "$tmpdir/out.csv")
  [[ "$actual" == "${expected[$ln]}" ]] || {
    printf 'line %s mismatch: expected %s, got %s\n' "$ln" "${expected[$ln]}" "$actual" >&2
    cat "$tmpdir/out.csv" >&2
    exit 1
  }
done

# Header + 3 data rows; absolutely no extra rows.
total=$(wc -l <"$tmpdir/out.csv")
[[ "$total" == "4" ]] || {
  printf 'expected 4 lines, got %s\n' "$total" >&2
  cat "$tmpdir/out.csv" >&2
  exit 1
}

readstat "$tmpdir/out.dta" >"$tmpdir/summary"
validator_assert_contains "$tmpdir/summary" 'Columns: 3'
validator_assert_contains "$tmpdir/summary" 'Rows: 3'
