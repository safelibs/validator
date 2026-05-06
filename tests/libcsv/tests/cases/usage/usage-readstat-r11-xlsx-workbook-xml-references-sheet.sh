#!/usr/bin/env bash
# @testcase: usage-readstat-r11-xlsx-workbook-xml-references-sheet
# @title: readstat XLSX xl/workbook.xml registers a single named worksheet
# @description: Builds an XLSX from a small CSV via DTA and parses xl/workbook.xml inside the OOXML zip to verify the workbook lists exactly one <sheet> element with sheetId="1" and a non-empty name attribute, locking in single-sheet workbook structure rather than only checking the per-sheet content.
# @timeout: 60
# @tags: usage, csv, xlsx, workbook
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
import re, sys, zipfile
with zipfile.ZipFile(sys.argv[1]) as z:
    wb = z.read('xl/workbook.xml').decode('utf-8')
sheet_tags = re.findall(r'<sheet\b[^/>]*/>', wb)
print(f'SHEET-COUNT={len(sheet_tags)}')
if sheet_tags:
    tag = sheet_tags[0]
    print('SHEETID-1-OK' if 'sheetId="1"' in tag else 'SHEETID-1-MISSING')
    name_match = re.search(r'\sname="([^"]+)"', tag)
    print('NAME-NONEMPTY-OK' if name_match and name_match.group(1) else 'NAME-NONEMPTY-MISSING')
PY

validator_assert_contains "$tmpdir/probe" 'SHEET-COUNT=1'
validator_assert_contains "$tmpdir/probe" 'SHEETID-1-OK'
validator_assert_contains "$tmpdir/probe" 'NAME-NONEMPTY-OK'
