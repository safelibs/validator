#!/usr/bin/env bash
# @testcase: usage-readstat-r21-csv-dta-string-roundtrip-four-rows
# @title: readstat CSV-DTA-CSV preserves four distinct ASCII strings in row order
# @description: Builds a four-row string-only CSV with metadata Stata STRING column, converts to DTA and back to CSV, then asserts the recovered stdout CSV preserves each ASCII token verbatim and in the same row order - locking in a four-row string roundtrip distinct from the existing five-row integer/three-string roundtrip tests.
# @timeout: 60
# @tags: usage, csv, dta, string, r21
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
label
red
green
blue
yellow
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"STRING","name":"label","label":"Label"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/mid.dta"
readstat "$tmpdir/mid.dta" - >"$tmpdir/out.csv"

for tok in red green blue yellow; do
    validator_assert_contains "$tmpdir/out.csv" "\"$tok\""
done

# Order check
positions=$(grep -nE '"red"|"green"|"blue"|"yellow"' "$tmpdir/out.csv" | cut -d: -f1 | tr '\n' ' ')
[[ "$positions" == "2 3 4 5 " ]] || {
    printf 'expected lines 2..5, got: %s\n' "$positions" >&2
    cat "$tmpdir/out.csv" >&2
    exit 1
}
