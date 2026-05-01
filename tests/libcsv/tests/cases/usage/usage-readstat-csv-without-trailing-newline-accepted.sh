#!/usr/bin/env bash
# @testcase: usage-readstat-csv-without-trailing-newline-accepted
# @title: readstat accepts CSV with no terminating newline
# @description: Writes a CSV whose final byte is a digit rather than a line feed and verifies readstat ingests both data rows, reports two rows in the DTA summary, and emits both records in the readback CSV. RFC 4180 makes the trailing CRLF optional and many spreadsheet exports omit it; this locks in the behavior.
# @timeout: 120
# @tags: usage, csv, line-endings, rfc4180
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Deliberately no terminating newline.
printf 'name,score\nalpha,42\nbeta,7' >"$tmpdir/in.csv"

# Sanity: last byte must be ASCII '7' (0x37), not 0x0a.
last_hex=$(tail -c 1 "$tmpdir/in.csv" | od -An -tx1 | tr -d ' \n')
if [[ "$last_hex" != "37" ]]; then
  printf 'fixture has unexpected trailing byte: %s\n' "$last_hex" >&2
  exit 1
fi

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"STRING","name":"name","label":"Name"},{"type":"NUMERIC","name":"score","label":"Score"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"
validator_require_file "$tmpdir/out.dta"

readstat "$tmpdir/out.dta" >"$tmpdir/summary"
validator_assert_contains "$tmpdir/summary" 'Columns: 2'
validator_assert_contains "$tmpdir/summary" 'Rows: 2'

readstat "$tmpdir/out.dta" - >"$tmpdir/out.csv"
validator_assert_contains "$tmpdir/out.csv" '"name","score"'
validator_assert_contains "$tmpdir/out.csv" '"alpha",42.000000'
validator_assert_contains "$tmpdir/out.csv" '"beta",7.000000'
