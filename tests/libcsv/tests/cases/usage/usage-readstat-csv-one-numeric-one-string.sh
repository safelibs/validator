#!/usr/bin/env bash
# @testcase: usage-readstat-csv-one-numeric-one-string
# @title: readstat multi-column CSV with one numeric and one string column
# @description: Builds a two-column CSV pairing a numeric column with a single string column and verifies that after a DTA round trip the readback header preserves the column order, the numeric column is rendered as six-decimal floats while the string column remains quoted, and the values are not transposed across the column boundary.
# @timeout: 180
# @tags: usage, csv, mixed
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
score,label
10,red
20,green
30,blue
40,yellow
50,purple
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"NUMERIC","name":"score","label":"Score"},{"type":"STRING","name":"label","label":"Label"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"
readstat "$tmpdir/out.dta" - >"$tmpdir/out.csv"

# Header keeps numeric-then-string column order.
header=$(sed -n '1p' "$tmpdir/out.csv")
[[ "$header" == '"score","label"' ]] || {
  printf 'unexpected header: %s\n' "$header" >&2
  exit 1
}

# Each data row: numeric on the left (unquoted, six-decimal), string on the
# right (quoted).
declare -A expected=(
  [2]='10.000000,"red"'
  [3]='20.000000,"green"'
  [4]='30.000000,"blue"'
  [5]='40.000000,"yellow"'
  [6]='50.000000,"purple"'
)
for ln in 2 3 4 5 6; do
  actual=$(sed -n "${ln}p" "$tmpdir/out.csv")
  [[ "$actual" == "${expected[$ln]}" ]] || {
    printf 'line %s mismatch: expected %s, got %s\n' "$ln" "${expected[$ln]}" "$actual" >&2
    cat "$tmpdir/out.csv" >&2
    exit 1
  }
done

# Numeric column must never appear quoted; string column must always appear quoted.
if grep -E '^"(10|20|30|40|50)\.' "$tmpdir/out.csv" >/dev/null; then
  printf 'numeric column unexpectedly quoted\n' >&2
  cat "$tmpdir/out.csv" >&2
  exit 1
fi
if grep -E '(red|green|blue|yellow|purple)$' "$tmpdir/out.csv" | grep -vE '"(red|green|blue|yellow|purple)"$' >/dev/null; then
  printf 'string column missing surrounding quotes\n' >&2
  cat "$tmpdir/out.csv" >&2
  exit 1
fi

readstat "$tmpdir/out.dta" >"$tmpdir/summary"
validator_assert_contains "$tmpdir/summary" 'Columns: 2'
validator_assert_contains "$tmpdir/summary" 'Rows: 5'
