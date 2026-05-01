#!/usr/bin/env bash
# @testcase: usage-readstat-csv-uppercase-extension-accepted
# @title: readstat treats .CSV uppercase as a CSV input
# @description: Stores the input fixture with an uppercase ".CSV" extension and verifies readstat still recognizes the format, ingests both rows, and writes a valid DTA. Documents that readstat's input-format dispatch is not strictly case-sensitive and matches the ".csv" path that lowercase fixtures exercise.
# @timeout: 120
# @tags: usage, csv, extension, case-insensitive
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/IN.CSV" <<'CSV'
name,value
alpha,1
beta,2
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"STRING","name":"name","label":"Name"},{"type":"NUMERIC","name":"value","label":"Value"}]}
JSON

readstat "$tmpdir/IN.CSV" "$tmpdir/meta.json" "$tmpdir/out.dta" \
  >"$tmpdir/stdout" 2>"$tmpdir/stderr"
cat "$tmpdir/stdout" "$tmpdir/stderr" >"$tmpdir/all"

# Diagnostic line emitted by the converter on success.
validator_assert_contains "$tmpdir/all" 'Converted 2 variables and 2 rows'
validator_require_file "$tmpdir/out.dta"

readstat "$tmpdir/out.dta" >"$tmpdir/summary"
validator_assert_contains "$tmpdir/summary" 'Columns: 2'
validator_assert_contains "$tmpdir/summary" 'Rows: 2'

readstat "$tmpdir/out.dta" - >"$tmpdir/out.csv"
validator_assert_contains "$tmpdir/out.csv" '"alpha",1.000000'
validator_assert_contains "$tmpdir/out.csv" '"beta",2.000000'
