#!/usr/bin/env bash
# @testcase: usage-readstat-r18-csv-five-row-dta-roundtrip
# @title: readstat round-trips a five-row two-column CSV through DTA back to stdout CSV
# @description: Builds a CSV with five data rows and two numeric columns, converts to .dta, then back to stdout CSV, and asserts the recovered output has exactly six lines (header + 5 rows) and contains every data cell — locking in row-count and content preservation for a slightly larger payload than the r17 tiny case.
# @timeout: 60
# @tags: usage, csv, dta, roundtrip, r18
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
m,n
10,20
30,40
50,60
70,80
90,100
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"NUMERIC","name":"m","label":"M"},{"type":"NUMERIC","name":"n","label":"N"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/mid.dta"
readstat "$tmpdir/mid.dta" - >"$tmpdir/out.csv"

line_count=$(wc -l <"$tmpdir/out.csv")
[[ "$line_count" -eq 6 ]] || {
    printf 'expected 6 lines, got %s\n' "$line_count" >&2
    cat "$tmpdir/out.csv" >&2
    exit 1
}
for token in 10 20 30 40 50 60 70 80 90 100; do
    validator_assert_contains "$tmpdir/out.csv" "$token"
done
