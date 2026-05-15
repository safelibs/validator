#!/usr/bin/env bash
# @testcase: usage-readstat-r19-dta-rows-line-matches-six-rows
# @title: readstat summary of a six-row DTA reports Rows: 6
# @description: Builds a single-column CSV with six data rows, converts to .dta, captures the summary output, and asserts it contains the literal "Rows: 6" - locking in the row-count summary line on a row count distinct from existing r17/r18 cases.
# @timeout: 60
# @tags: usage, csv, dta, summary, rows, r19
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
n
1
2
3
4
5
6
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"NUMERIC","name":"n","label":"N"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"
readstat "$tmpdir/out.dta" >"$tmpdir/summary"

validator_assert_contains "$tmpdir/summary" 'Rows: 6'
