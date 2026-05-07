#!/usr/bin/env bash
# @testcase: usage-readstat-r12-csv-quoted-newline-roundtrip
# @title: readstat preserves a quoted CRLF in a string field across DTA roundtrip
# @description: Round-trips a quoted CSV field whose embedded newline is a CRLF (carriage-return + line-feed) through DTA and back to CSV and asserts the multi-line content reappears in the output, distinguishing the CRLF embedded-newline case from the LF-only case.
# @timeout: 120
# @tags: usage, csv, dta, quoted-newline
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# CRLF inside a quoted field. Two data rows total.
printf 'name,score\n"alpha\r\nbeta",10\ngamma,20\n' >"$tmpdir/in.csv"

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"STRING","name":"name","label":"Name"},{"type":"NUMERIC","name":"score","label":"Score"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"
readstat "$tmpdir/out.dta" >"$tmpdir/summary"

# Two rows means CRLF inside quotes was treated as one record, not two.
validator_assert_contains "$tmpdir/summary" 'Rows: 2'
validator_assert_contains "$tmpdir/summary" 'Columns: 2'

readstat "$tmpdir/out.dta" - >"$tmpdir/out.csv"
validator_assert_contains "$tmpdir/out.csv" '"alpha'
validator_assert_contains "$tmpdir/out.csv" 'beta"'
validator_assert_contains "$tmpdir/out.csv" '"gamma",20.000000'
