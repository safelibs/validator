#!/usr/bin/env bash
# @testcase: usage-readstat-r13-xpt-summary-rows-minus-one
# @title: readstat XPT summary reports Rows: -1 because XPORT lacks a row count
# @description: Builds an XPT file from a CSV via DTA and verifies the readstat summary reports "Rows: -1" rather than the actual row count, locking in the well-known XPORT behaviour where the writer cannot report a row count from the header alone — distinguishing the XPT path from DTA and SAS7BDAT which report the precise row count.
# @timeout: 60
# @tags: usage, csv, xpt, rows
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
id,name
1,alice
2,bob
3,carol
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"NUMERIC","name":"id","label":"ID"},{"type":"STRING","name":"name","label":"Name"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/mid.dta"
readstat "$tmpdir/mid.dta" "$tmpdir/out.xpt"
readstat "$tmpdir/out.xpt" >"$tmpdir/summary"

validator_assert_contains "$tmpdir/summary" 'Format: SAS transport file (XPORT)'
grep -E '^Rows: -1$' "$tmpdir/summary" >/dev/null || {
  printf 'XPT summary did not pin Rows to -1\n' >&2
  cat "$tmpdir/summary" >&2
  exit 1
}
# Sanity: this is the same XPT file we wrote, with two columns.
validator_assert_contains "$tmpdir/summary" 'Columns: 2'
