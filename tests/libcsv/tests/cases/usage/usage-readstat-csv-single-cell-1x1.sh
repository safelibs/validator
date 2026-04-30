#!/usr/bin/env bash
# @testcase: usage-readstat-csv-single-cell-1x1
# @title: readstat 1x1 CSV
# @description: Converts a CSV containing exactly one column and one data row through DTA and verifies the summary, header, and single value all survive.
# @timeout: 180
# @tags: usage, csv, minimal
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
score
42
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"NUMERIC","name":"score","label":"Score"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"

readstat "$tmpdir/out.dta" >"$tmpdir/summary"
validator_assert_contains "$tmpdir/summary" 'Columns: 1'
validator_assert_contains "$tmpdir/summary" 'Rows: 1'

readstat "$tmpdir/out.dta" - >"$tmpdir/out.csv"

# Exactly two lines: header and single data row.
total=$(wc -l <"$tmpdir/out.csv")
[[ "$total" == "2" ]] || {
  printf 'expected 2 output lines, got %s\n' "$total" >&2
  cat "$tmpdir/out.csv" >&2
  exit 1
}

header=$(sed -n '1p' "$tmpdir/out.csv")
[[ "$header" == '"score"' ]] || {
  printf 'unexpected header: %s\n' "$header" >&2
  exit 1
}

data=$(sed -n '2p' "$tmpdir/out.csv")
[[ "$data" == "42.000000" ]] || {
  printf 'unexpected single data value: %s\n' "$data" >&2
  exit 1
}
