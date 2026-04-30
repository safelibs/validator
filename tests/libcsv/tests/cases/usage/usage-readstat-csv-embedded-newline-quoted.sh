#!/usr/bin/env bash
# @testcase: usage-readstat-csv-embedded-newline-quoted
# @title: readstat embedded newline in quoted CSV field
# @description: Parses a CSV row whose quoted string field contains a literal newline and verifies the multi-line value survives through DTA back to CSV.
# @timeout: 180
# @tags: usage, csv, quoting
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Quoted field with embedded LF. Two data rows total.
printf 'name,score\n"line1\nline2",42\nbeta,7\n' >"$tmpdir/in.csv"

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"STRING","name":"name","label":"Name"},{"type":"NUMERIC","name":"score","label":"Score"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"

readstat "$tmpdir/out.dta" >"$tmpdir/summary"
validator_assert_contains "$tmpdir/summary" 'Columns: 2'
validator_assert_contains "$tmpdir/summary" 'Rows: 2'

readstat "$tmpdir/out.dta" - >"$tmpdir/out.csv"
validator_assert_contains "$tmpdir/out.csv" '"line1'
validator_assert_contains "$tmpdir/out.csv" 'line2",42.000000'
validator_assert_contains "$tmpdir/out.csv" '"beta",7.000000'
