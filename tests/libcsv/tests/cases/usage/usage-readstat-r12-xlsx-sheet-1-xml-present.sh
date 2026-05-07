#!/usr/bin/env bash
# @testcase: usage-readstat-r12-xlsx-sheet-1-xml-present
# @title: readstat XLSX archive contains xl/worksheets/sheet1.xml
# @description: Builds an XLSX from a CSV via DTA and verifies the resulting OOXML zip archive contains the worksheet entry "xl/worksheets/sheet1.xml", locking in the conventional sheet path used by the readstat XLSX writer.
# @timeout: 60
# @tags: usage, csv, xlsx, archive
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
id,name
1,alice
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"NUMERIC","name":"id","label":"ID"},{"type":"STRING","name":"name","label":"Name"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/mid.dta"
readstat "$tmpdir/mid.dta" "$tmpdir/out.xlsx"
validator_require_file "$tmpdir/out.xlsx"

python3 - "$tmpdir/out.xlsx" >"$tmpdir/probe" <<'PY'
import sys, zipfile
with zipfile.ZipFile(sys.argv[1]) as z:
    names = set(z.namelist())
print('SHEET1-OK' if 'xl/worksheets/sheet1.xml' in names else 'SHEET1-MISSING')
print('WORKBOOK-OK' if 'xl/workbook.xml' in names else 'WORKBOOK-MISSING')
PY

validator_assert_contains "$tmpdir/probe" 'SHEET1-OK'
validator_assert_contains "$tmpdir/probe" 'WORKBOOK-OK'
