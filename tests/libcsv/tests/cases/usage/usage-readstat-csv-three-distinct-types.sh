#!/usr/bin/env bash
# @testcase: usage-readstat-csv-three-distinct-types
# @title: readstat three-column CSV with string, integer-valued, and float-valued columns
# @description: Builds a three-column CSV pairing a STRING column with two NUMERIC columns whose data is shaped as integers in column 2 and as non-integral floats in column 3, converts through DTA, and verifies the readback header order is preserved, the string column stays quoted, the integer-valued numeric column renders with .000000 suffix, and the float-valued numeric column renders the fractional part exactly.
# @timeout: 180
# @tags: usage, csv, mixed, types
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
label,count,ratio
red,1,0.125
green,2,0.250
blue,3,0.375
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"STRING","name":"label","label":"Label"},{"type":"NUMERIC","name":"count","label":"Count"},{"type":"NUMERIC","name":"ratio","label":"Ratio"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"
readstat "$tmpdir/out.dta" - >"$tmpdir/out.csv"

# Header keeps the three-column order.
header=$(sed -n '1p' "$tmpdir/out.csv")
[[ "$header" == '"label","count","ratio"' ]] || {
  printf 'unexpected header: %s\n' "$header" >&2
  exit 1
}

# Data lines: string is quoted, integer-valued numeric ends in .000000, float numeric carries its fractional digits.
declare -A expected=(
  [2]='"red",1.000000,0.125000'
  [3]='"green",2.000000,0.250000'
  [4]='"blue",3.000000,0.375000'
)
for ln in 2 3 4; do
  actual=$(sed -n "${ln}p" "$tmpdir/out.csv")
  [[ "$actual" == "${expected[$ln]}" ]] || {
    printf 'line %s mismatch: expected %s, got %s\n' "$ln" "${expected[$ln]}" "$actual" >&2
    cat "$tmpdir/out.csv" >&2
    exit 1
  }
done

# String column must always be quoted.
for word in red green blue; do
  validator_assert_contains "$tmpdir/out.csv" "\"$word\","
done

# Integer-valued column must always render with the .000000 short form.
int_zero_count=$(grep -cE ',[0-9]+\.000000,' "$tmpdir/out.csv")
[[ "$int_zero_count" == "3" ]] || {
  printf 'expected 3 integer-valued cells with .000000 form, got %s\n' "$int_zero_count" >&2
  cat "$tmpdir/out.csv" >&2
  exit 1
}

# Float-valued column must render the exact fractional values.
for frac in 0.125000 0.250000 0.375000; do
  validator_assert_contains "$tmpdir/out.csv" "$frac"
done

# Header + 3 data rows.
total=$(wc -l <"$tmpdir/out.csv")
[[ "$total" == "4" ]] || {
  printf 'expected 4 lines, got %s\n' "$total" >&2
  exit 1
}

readstat "$tmpdir/out.dta" >"$tmpdir/summary"
validator_assert_contains "$tmpdir/summary" 'Columns: 3'
validator_assert_contains "$tmpdir/summary" 'Rows: 3'
