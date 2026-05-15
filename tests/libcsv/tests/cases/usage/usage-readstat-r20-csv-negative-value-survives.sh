#!/usr/bin/env bash
# @testcase: usage-readstat-r20-csv-negative-value-survives
# @title: readstat CSV-DTA-CSV preserves a negative integer value
# @description: Builds a CSV containing a negative integer (-42), converts through .dta back to stdout CSV, and asserts the recovered output contains the literal "-42" - locking in sign preservation through the DTA writer/reader.
# @timeout: 60
# @tags: usage, csv, dta, negative, r20
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
v
-42
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"NUMERIC","name":"v","label":"V"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/mid.dta"
readstat "$tmpdir/mid.dta" - >"$tmpdir/out.csv"

validator_assert_contains "$tmpdir/out.csv" '-42'
