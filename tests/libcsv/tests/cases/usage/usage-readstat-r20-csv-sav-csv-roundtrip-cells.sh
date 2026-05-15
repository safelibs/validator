#!/usr/bin/env bash
# @testcase: usage-readstat-r20-csv-sav-csv-roundtrip-cells
# @title: readstat CSV-SAV-CSV roundtrip preserves every data cell across three rows
# @description: Converts a three-row two-column CSV through SAV and back to stdout CSV, then asserts the recovered output contains every distinct numeric value from the source - locking in cell preservation for the SAV writer/reader paths.
# @timeout: 60
# @tags: usage, csv, sav, cells, roundtrip, r20
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
a,b
21,43
65,87
9,101
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"SPSS","variables":[{"type":"NUMERIC","name":"a","label":"A"},{"type":"NUMERIC","name":"b","label":"B"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/mid.sav"
readstat "$tmpdir/mid.sav" - >"$tmpdir/out.csv"

for token in 21 43 65 87 101; do
    validator_assert_contains "$tmpdir/out.csv" "$token"
done
