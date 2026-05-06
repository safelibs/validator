#!/usr/bin/env bash
# @testcase: usage-readstat-r11-xlsx-rels-targets-workbook-xml
# @title: readstat XLSX root _rels/.rels declares xl/workbook.xml as the office document target
# @description: Builds an XLSX from a small CSV via DTA and parses _rels/.rels inside the OOXML zip to verify the package-level relationship of type "officeDocument" targets exactly "xl/workbook.xml", locking in the OOXML root-relationships layout produced by the readstat XLSX writer.
# @timeout: 60
# @tags: usage, csv, xlsx, rels
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
    rels = z.read('_rels/.rels').decode('utf-8')
office_match = re.search(
    r'<Relationship\b[^/>]*Type="[^"]*officeDocument"[^/>]*Target="([^"]+)"',
    rels,
)
target = office_match.group(1) if office_match else ''
print(f'OFFICE-DOC-TARGET={target}')
print('XLNS-OK' if 'http://schemas.openxmlformats.org/package/2006/relationships' in rels else 'XLNS-MISSING')
PY

validator_assert_contains "$tmpdir/probe" 'OFFICE-DOC-TARGET=xl/workbook.xml'
validator_assert_contains "$tmpdir/probe" 'XLNS-OK'
