#!/usr/bin/env bash
# @testcase: usage-readstat-csv-crlf-line-endings
# @title: readstat CRLF CSV input
# @description: Feeds a CRLF-terminated CSV to readstat and verifies the rows are parsed and exported back to CSV without extra carriage returns.
# @timeout: 180
# @tags: usage, csv, crlf
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'name,score\r\nalpha,42\r\nbeta,7\r\n' >"$tmpdir/in.csv"

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"STRING","name":"name","label":"Name"},{"type":"NUMERIC","name":"score","label":"Score"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"
readstat "$tmpdir/out.dta" - >"$tmpdir/out.csv"

validator_assert_contains "$tmpdir/out.csv" '"name","score"'
validator_assert_contains "$tmpdir/out.csv" '"alpha",42.000000'
validator_assert_contains "$tmpdir/out.csv" '"beta",7.000000'

# Output CSV must use LF line endings, not CRLF echoed from input.
if grep -q $'\r' "$tmpdir/out.csv"; then
  printf 'unexpected CR bytes in readstat CSV output\n' >&2
  cat -A "$tmpdir/out.csv" >&2
  exit 1
fi

readstat "$tmpdir/out.dta" >"$tmpdir/summary"
validator_assert_contains "$tmpdir/summary" 'Columns: 2'
validator_assert_contains "$tmpdir/summary" 'Rows: 2'
