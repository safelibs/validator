#!/usr/bin/env bash
# @testcase: usage-readstat-r17-tiny-csv-stdout-shape
# @title: readstat round-trips a 3-row 2-column CSV through DTA back to stdout CSV with stable shape
# @description: Converts a CSV with three data rows and two columns to .dta then back to CSV via stdout, asserting the recovered CSV has exactly four lines (header + 3 rows) and contains all six data cell tokens — locking in tiny-grid shape preservation.
# @timeout: 60
# @tags: usage, csv, dta, roundtrip
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
x,y
11,22
33,44
55,66
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"NUMERIC","name":"x","label":"X"},{"type":"NUMERIC","name":"y","label":"Y"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/mid.dta"
readstat "$tmpdir/mid.dta" - >"$tmpdir/out.csv"

line_count=$(wc -l <"$tmpdir/out.csv")
[[ "$line_count" -eq 4 ]] || {
    printf 'expected 4 lines, got %s\n' "$line_count" >&2
    cat "$tmpdir/out.csv" >&2
    exit 1
}
for token in 11 22 33 44 55 66; do
    validator_assert_contains "$tmpdir/out.csv" "$token"
done
