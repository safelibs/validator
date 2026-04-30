#!/usr/bin/env bash
# @testcase: usage-readstat-csv-formula-double-relation
# @title: readstat numeric column doubling formula preserved across DTA round trip
# @description: Builds a CSV with two numeric columns where column2 equals column1 multiplied by 2 across five data rows (1->2, 2->4, 3->6, 4->8, 5->10), converts through DTA, and verifies in the readback that for each data row the second-column numeric value is exactly twice the first-column numeric value, computed by parsing the integer portions of the six-decimal short forms with awk.
# @timeout: 180
# @tags: usage, csv, numeric, formula
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
x,y
1,2
2,4
3,6
4,8
5,10
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"NUMERIC","name":"x","label":"X"},{"type":"NUMERIC","name":"y","label":"Y"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"
readstat "$tmpdir/out.dta" - >"$tmpdir/out.csv"

validator_assert_contains "$tmpdir/out.csv" '"x","y"'

# Each row must satisfy y == 2 * x.
for ln in 2 3 4 5 6; do
  line=$(sed -n "${ln}p" "$tmpdir/out.csv")
  x=$(printf '%s' "$line" | cut -d, -f1)
  y=$(printf '%s' "$line" | cut -d, -f2)

  # Each cell must look like a six-decimal numeric value.
  if ! [[ "$x" =~ ^[0-9]+\.[0-9]{6}$ ]]; then
    printf 'line %s column1 not six-decimal numeric: %s\n' "$ln" "$x" >&2
    exit 1
  fi
  if ! [[ "$y" =~ ^[0-9]+\.[0-9]{6}$ ]]; then
    printf 'line %s column2 not six-decimal numeric: %s\n' "$ln" "$y" >&2
    exit 1
  fi

  # Use awk so we work on the floats robustly.
  ratio_ok=$(awk -v a="$x" -v b="$y" 'BEGIN { print (b == 2 * a) ? "1" : "0" }')
  if [[ "$ratio_ok" != "1" ]]; then
    printf 'formula y==2*x violated on line %s: x=%s y=%s\n' "$ln" "$x" "$y" >&2
    cat "$tmpdir/out.csv" >&2
    exit 1
  fi
done

# Sanity: the exact expected pairs all appear in the readback.
for pair in '1.000000,2.000000' '2.000000,4.000000' '3.000000,6.000000' '4.000000,8.000000' '5.000000,10.000000'; do
  validator_assert_contains "$tmpdir/out.csv" "$pair"
done

# Header + 5 rows.
total=$(wc -l <"$tmpdir/out.csv")
[[ "$total" == "6" ]] || {
  printf 'expected 6 lines, got %s\n' "$total" >&2
  exit 1
}

readstat "$tmpdir/out.dta" >"$tmpdir/summary"
validator_assert_contains "$tmpdir/summary" 'Columns: 2'
validator_assert_contains "$tmpdir/summary" 'Rows: 5'
