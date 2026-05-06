#!/usr/bin/env bash
# @testcase: usage-readstat-r9-csv-tab-not-comma-rejected
# @title: readstat preserves tab separators as cell content
# @description: Feeds a tab-separated input through readstat and verifies the comma parser treats the line as a single column rather than splitting on tabs.
# @timeout: 180
# @tags: usage, csv, parsing
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'row\n1\t2\t3\n4\t5\t6\n' >"$tmpdir/in.csv"

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"STRING","name":"row","label":"R"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"
readstat "$tmpdir/out.dta" >"$tmpdir/summary"

validator_assert_contains "$tmpdir/summary" 'Columns: 1'
validator_assert_contains "$tmpdir/summary" 'Rows: 2'
