#!/usr/bin/env bash
# @testcase: usage-readstat-r9-csv-spss-sav-roundtrip
# @title: readstat CSV through SPSS SAV format
# @description: Converts a CSV through the SPSS .sav format and back to CSV and confirms the cell values reappear unchanged.
# @timeout: 180
# @tags: usage, csv, spss
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
alpha,beta,gamma
1,2,3
4,5,6
7,8,9
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"SPSS","variables":[{"type":"NUMERIC","name":"alpha","label":"A"},{"type":"NUMERIC","name":"beta","label":"B"},{"type":"NUMERIC","name":"gamma","label":"G"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.sav"
readstat "$tmpdir/out.sav" >"$tmpdir/summary"
validator_assert_contains "$tmpdir/summary" 'Columns: 3'
validator_assert_contains "$tmpdir/summary" 'Rows: 3'

readstat "$tmpdir/out.sav" - >"$tmpdir/out.csv"
validator_assert_contains "$tmpdir/out.csv" '"alpha","beta","gamma"'
validator_assert_contains "$tmpdir/out.csv" '1.000000,2.000000,3.000000'
validator_assert_contains "$tmpdir/out.csv" '7.000000,8.000000,9.000000'
