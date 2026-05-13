#!/usr/bin/env bash
# @testcase: usage-readstat-r16-csv-embedded-newline-quoted-field
# @title: readstat ingests a CSV with a newline inside a quoted string cell
# @description: Builds a CSV whose first string field contains an embedded newline within a quoted cell and asserts readstat reads it as a single row with 2 columns by checking the .dta summary reports Rows: 1 and Columns: 2.
# @timeout: 60
# @tags: usage, csv, quoting, embedded-newline
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 -c "
import io
with open('$tmpdir/in.csv','w', newline='') as f:
    f.write('label,n\r\n')
    f.write('\"line one\nline two\",7\r\n')
"

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"STRING","name":"label","label":"L"},{"type":"NUMERIC","name":"n","label":"N"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"
readstat "$tmpdir/out.dta" >"$tmpdir/summary"

validator_assert_contains "$tmpdir/summary" 'Rows: 1'
validator_assert_contains "$tmpdir/summary" 'Columns: 2'
