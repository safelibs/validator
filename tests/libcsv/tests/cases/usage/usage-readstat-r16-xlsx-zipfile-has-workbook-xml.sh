#!/usr/bin/env bash
# @testcase: usage-readstat-r16-xlsx-zipfile-has-workbook-xml
# @title: readstat-built xlsx contains xl/workbook.xml when inspected via python zipfile
# @description: Converts CSV through DTA into an XLSX via readstat, then uses python3 zipfile to list the archive entries and asserts the standard "xl/workbook.xml" member is present — locking in the OOXML container structure of the readstat XLSX writer without relying on unzip or openpyxl.
# @timeout: 60
# @tags: usage, csv, xlsx, ooxml
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
id,score
1,10
2,20
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"NUMERIC","name":"id","label":"ID"},{"type":"NUMERIC","name":"score","label":"Score"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/mid.dta"
readstat "$tmpdir/mid.dta" "$tmpdir/out.xlsx"

python3 - "$tmpdir/out.xlsx" >"$tmpdir/entries" <<'PY'
import sys, zipfile
with zipfile.ZipFile(sys.argv[1]) as z:
    for name in z.namelist():
        print(name)
PY

validator_assert_contains "$tmpdir/entries" 'xl/workbook.xml'
