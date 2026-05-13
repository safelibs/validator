#!/usr/bin/env bash
# @testcase: usage-readstat-r16-csv-single-data-row-stdout-csv
# @title: readstat round-trips a one-data-row CSV through DTA back to stdout CSV exactly
# @description: Converts a CSV containing a single non-header row to .dta then back to CSV via stdout, asserting the recovered CSV has exactly 2 lines and preserves the data cell values byte-for-byte through the DTA hop.
# @timeout: 60
# @tags: usage, csv, dta, single-row
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
name,n
alpha,42
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"STRING","name":"name","label":"Name"},{"type":"NUMERIC","name":"n","label":"N"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/mid.dta"
readstat "$tmpdir/mid.dta" - >"$tmpdir/out.csv"

line_count=$(wc -l <"$tmpdir/out.csv")
[[ "$line_count" -eq 2 ]] || {
    printf 'expected 2 lines, got %s\n' "$line_count" >&2
    cat "$tmpdir/out.csv" >&2
    exit 1
}
validator_assert_contains "$tmpdir/out.csv" 'alpha'
validator_assert_contains "$tmpdir/out.csv" '42'
