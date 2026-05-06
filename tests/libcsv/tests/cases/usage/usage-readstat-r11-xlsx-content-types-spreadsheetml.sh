#!/usr/bin/env bash
# @testcase: usage-readstat-r11-xlsx-content-types-spreadsheetml
# @title: readstat XLSX [Content_Types].xml advertises spreadsheetml worksheet content type
# @description: Builds an XLSX from a small CSV via DTA and parses [Content_Types].xml inside the OOXML zip to verify the worksheet content type "application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml" is registered, locking in OOXML conformance of the readstat XLSX writer beyond the previously-checked sheet1.xml dimension.
# @timeout: 60
# @tags: usage, csv, xlsx, content-types
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
    ct = z.read('[Content_Types].xml').decode('utf-8')
print('TYPES-ROOT-OK' if '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">' in ct else 'TYPES-ROOT-MISSING')
print('WORKSHEET-CT-OK' if 'application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml' in ct else 'WORKSHEET-CT-MISSING')
PY

validator_assert_contains "$tmpdir/probe" 'TYPES-ROOT-OK'
validator_assert_contains "$tmpdir/probe" 'WORKSHEET-CT-OK'
