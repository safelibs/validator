#!/usr/bin/env bash
# @testcase: usage-readstat-r19-csv-dta-csv-data-cells-preserved
# @title: readstat CSV-DTA-CSV roundtrip preserves every data cell across three rows
# @description: Converts a three-row two-column CSV through DTA and back to stdout CSV, then asserts the recovered output contains every distinct numeric value from the source - locking in cell-by-cell content preservation for a small mixed-value payload.
# @timeout: 60
# @tags: usage, csv, dta, cells, roundtrip, r19
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
a,b
12,34
56,78
90,11
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"NUMERIC","name":"a","label":"A"},{"type":"NUMERIC","name":"b","label":"B"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/mid.dta"
readstat "$tmpdir/mid.dta" - >"$tmpdir/out.csv"

for token in 12 34 56 78 90 11; do
    validator_assert_contains "$tmpdir/out.csv" "$token"
done
