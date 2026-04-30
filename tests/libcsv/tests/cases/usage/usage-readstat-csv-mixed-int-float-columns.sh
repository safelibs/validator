#!/usr/bin/env bash
# @testcase: usage-readstat-csv-mixed-int-float-columns
# @title: readstat mixed int and float numeric columns
# @description: Converts a CSV whose first numeric column carries integers and second numeric column carries non-integral floats through DTA and verifies both columns survive at six-decimal precision without one column collapsing into the other type.
# @timeout: 180
# @tags: usage, csv, numeric
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
count,ratio
1,0.25
2,0.75
3,1.25
4,1.75
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"NUMERIC","name":"count","label":"Count"},{"type":"NUMERIC","name":"ratio","label":"Ratio"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"
readstat "$tmpdir/out.dta" - >"$tmpdir/out.csv"

validator_assert_contains "$tmpdir/out.csv" '"count","ratio"'
validator_assert_contains "$tmpdir/out.csv" '1.000000,0.250000'
validator_assert_contains "$tmpdir/out.csv" '2.000000,0.750000'
validator_assert_contains "$tmpdir/out.csv" '3.000000,1.250000'
validator_assert_contains "$tmpdir/out.csv" '4.000000,1.750000'

# Ints must not have been emitted in scientific or compressed form.
if grep -E '^[0-9]+e' "$tmpdir/out.csv" >/dev/null; then
  printf 'unexpected scientific notation\n' >&2
  cat "$tmpdir/out.csv" >&2
  exit 1
fi

# Header + 4 rows.
total=$(wc -l <"$tmpdir/out.csv")
[[ "$total" == "5" ]] || {
  printf 'expected 5 lines, got %s\n' "$total" >&2
  exit 1
}

readstat "$tmpdir/out.dta" >"$tmpdir/summary"
validator_assert_contains "$tmpdir/summary" 'Columns: 2'
validator_assert_contains "$tmpdir/summary" 'Rows: 4'
