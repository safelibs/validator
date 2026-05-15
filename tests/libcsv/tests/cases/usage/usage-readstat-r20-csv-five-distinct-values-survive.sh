#!/usr/bin/env bash
# @testcase: usage-readstat-r20-csv-five-distinct-values-survive
# @title: readstat CSV-DTA-CSV preserves five distinct integer values in a single column
# @description: Builds a single-column CSV with five distinct integers, converts to .dta and back to stdout CSV, then asserts each integer is recovered in the output - locking in single-column row preservation through the DTA roundtrip path.
# @timeout: 60
# @tags: usage, csv, dta, single-column, integers, r20
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
v
2
5
9
14
27
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"NUMERIC","name":"v","label":"V"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/mid.dta"
readstat "$tmpdir/mid.dta" - >"$tmpdir/out.csv"

for token in 2 5 9 14 27; do
    validator_assert_contains "$tmpdir/out.csv" "$token"
done
