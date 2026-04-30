#!/usr/bin/env bash
# @testcase: usage-readstat-csv-to-xlsx-output
# @title: readstat CSV to XLSX output
# @description: Converts CSV through DTA into an XLSX workbook and verifies the workbook is a valid zip with the expected shared strings and cell value.
# @timeout: 180
# @tags: usage, csv, xlsx
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
name,score
alpha,42
beta,7
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"STRING","name":"name","label":"Name"},{"type":"NUMERIC","name":"score","label":"Score"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/mid.dta"
readstat "$tmpdir/mid.dta" "$tmpdir/out.xlsx"
validator_require_file "$tmpdir/out.xlsx"

file "$tmpdir/out.xlsx" >"$tmpdir/file-type"
validator_assert_contains "$tmpdir/file-type" 'Microsoft Excel 2007+'

python3 - "$tmpdir/out.xlsx" >"$tmpdir/probe" <<'PY'
import sys, zipfile
path = sys.argv[1]
with zipfile.ZipFile(path) as z:
    names = z.namelist()
    assert 'xl/worksheets/sheet1.xml' in names, names
    assert 'xl/sharedStrings.xml' in names, names
    sheet = z.read('xl/worksheets/sheet1.xml').decode('utf-8')
    shared = z.read('xl/sharedStrings.xml').decode('utf-8')
print('SHEET-DIM-OK' if 'A1:B3' in sheet else 'SHEET-DIM-MISSING')
print('SCORE-CELL-OK' if '<v>42</v>' in sheet else 'SCORE-CELL-MISSING')
print('STRING-NAME-OK' if '<t>name</t>' in shared else 'STRING-NAME-MISSING')
print('STRING-ALPHA-OK' if '<t>alpha</t>' in shared else 'STRING-ALPHA-MISSING')
PY

validator_assert_contains "$tmpdir/probe" 'SHEET-DIM-OK'
validator_assert_contains "$tmpdir/probe" 'SCORE-CELL-OK'
validator_assert_contains "$tmpdir/probe" 'STRING-NAME-OK'
validator_assert_contains "$tmpdir/probe" 'STRING-ALPHA-OK'
