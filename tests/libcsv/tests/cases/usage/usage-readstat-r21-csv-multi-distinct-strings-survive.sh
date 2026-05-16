#!/usr/bin/env bash
# @testcase: usage-readstat-r21-csv-multi-distinct-strings-survive
# @title: readstat CSV-DTA-CSV roundtrip preserves six distinct ASCII strings
# @description: Builds a six-row string CSV with non-overlapping tokens, converts through .dta and back to stdout CSV, and asserts each unique token appears in the recovered output - locking in a six-distinct-string survival contract distinct from prior four/five-row string tests.
# @timeout: 60
# @tags: usage, csv, dta, multi-string, r21
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
label
mercury
venus
earth
mars
jupiter
saturn
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"STRING","name":"label","label":"Label"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/mid.dta"
readstat "$tmpdir/mid.dta" - >"$tmpdir/out.csv"

for tok in mercury venus earth mars jupiter saturn; do
    validator_assert_contains "$tmpdir/out.csv" "$tok"
done
