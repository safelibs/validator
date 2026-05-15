#!/usr/bin/env bash
# @testcase: usage-readstat-r20-csv-decimal-roundtrip-preserved
# @title: readstat CSV-DTA-CSV preserves a decimal fraction (3.5) through the roundtrip
# @description: Builds a one-row CSV containing 3.5, converts through .dta and back to stdout CSV, and asserts the recovered output contains the token "3.5" - locking in fractional-value preservation through the DTA roundtrip.
# @timeout: 60
# @tags: usage, csv, dta, decimal, r20
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
v
3.5
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"NUMERIC","name":"v","label":"V"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/mid.dta"
readstat "$tmpdir/mid.dta" - >"$tmpdir/out.csv"

validator_assert_contains "$tmpdir/out.csv" '3.5'
