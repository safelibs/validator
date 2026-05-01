#!/usr/bin/env bash
# @testcase: usage-readstat-xlsx-sheet-dimension-larger
# @title: readstat XLSX sheet dimension reflects three columns and eight data rows
# @description: Builds an XLSX from an eight-row three-column CSV via DTA and parses the sheet1 XML to verify the dimension attribute is exactly A1:C9 (three columns and one header plus eight data rows) and that the eighth data row contains the trailing string code reference for the final group entry.
# @timeout: 180
# @tags: usage, csv, xlsx, dimension
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
id,val,grp
1,10,A
2,20,B
3,30,C
4,40,D
5,50,E
6,60,F
7,70,G
8,80,H
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"NUMERIC","name":"id","label":"ID"},{"type":"NUMERIC","name":"val","label":"Val"},{"type":"STRING","name":"grp","label":"Grp"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/mid.dta"
readstat "$tmpdir/mid.dta" "$tmpdir/out.xlsx"
validator_require_file "$tmpdir/out.xlsx"

python3 - "$tmpdir/out.xlsx" >"$tmpdir/probe" <<'PY'
import sys, zipfile
path = sys.argv[1]
with zipfile.ZipFile(path) as z:
    sheet = z.read('xl/worksheets/sheet1.xml').decode('utf-8')
    shared = z.read('xl/sharedStrings.xml').decode('utf-8')
print('DIM-OK' if 'dimension ref="A1:C9"' in sheet else 'DIM-MISSING')
# Last numeric in column B is 80.
print('LAST-VAL-OK' if '<v>80</v>' in sheet else 'LAST-VAL-MISSING')
# All eight grp letters present in shared strings.
all_letters = all(f'<t>{c}</t>' in shared for c in 'ABCDEFGH')
print('ALL-LETTERS-OK' if all_letters else 'ALL-LETTERS-MISSING')
PY

validator_assert_contains "$tmpdir/probe" 'DIM-OK'
validator_assert_contains "$tmpdir/probe" 'LAST-VAL-OK'
validator_assert_contains "$tmpdir/probe" 'ALL-LETTERS-OK'
