#!/usr/bin/env bash
# @testcase: usage-readstat-csv-positive-negative-correlation
# @title: readstat CSV two correlated numeric columns
# @description: Builds a CSV with two distinct numeric columns where one is positively correlated with row index and another is negatively correlated, converts through DTA, and verifies the monotonic increase and decrease survive readback exactly.
# @timeout: 180
# @tags: usage, csv, numeric
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# pos goes 1,2,3,4,5; neg goes 50,40,30,20,10. Pearson r is exactly +1 and -1.
cat >"$tmpdir/in.csv" <<'CSV'
pos,neg
1,50
2,40
3,30
4,20
5,10
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"NUMERIC","name":"pos","label":"Positive"},{"type":"NUMERIC","name":"neg","label":"Negative"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"
readstat "$tmpdir/out.dta" - >"$tmpdir/out.csv"

validator_assert_contains "$tmpdir/out.csv" '"pos","neg"'
validator_assert_contains "$tmpdir/out.csv" '1.000000,50.000000'
validator_assert_contains "$tmpdir/out.csv" '2.000000,40.000000'
validator_assert_contains "$tmpdir/out.csv" '3.000000,30.000000'
validator_assert_contains "$tmpdir/out.csv" '4.000000,20.000000'
validator_assert_contains "$tmpdir/out.csv" '5.000000,10.000000'

# Verify monotonic ordering survives in the output line order.
prev_pos=""
prev_neg=""
while IFS=, read -r p n; do
  case "$p" in
    '"pos"') continue ;;
  esac
  if [[ -n "$prev_pos" ]]; then
    awk -v a="$prev_pos" -v b="$p" 'BEGIN{exit !(a < b)}' || {
      printf 'pos not increasing: %s -> %s\n' "$prev_pos" "$p" >&2
      exit 1
    }
    awk -v a="$prev_neg" -v b="$n" 'BEGIN{exit !(a > b)}' || {
      printf 'neg not decreasing: %s -> %s\n' "$prev_neg" "$n" >&2
      exit 1
    }
  fi
  prev_pos=$p
  prev_neg=$n
done <"$tmpdir/out.csv"

readstat "$tmpdir/out.dta" >"$tmpdir/summary"
validator_assert_contains "$tmpdir/summary" 'Columns: 2'
validator_assert_contains "$tmpdir/summary" 'Rows: 5'
