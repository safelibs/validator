#!/usr/bin/env bash
# @testcase: usage-readstat-r14-csv-to-xlsx-via-dta-content-type
# @title: readstat-produced XLSX is a ZIP container that unzips to expose [Content_Types].xml
# @description: Round-trips a CSV through DTA and into XLSX via readstat, then runs the unzip(1) listing on the result and asserts it includes the "[Content_Types].xml" member that every Office Open XML package must contain — locking in that the XLSX writer emits a structurally valid ZIP/OOXML archive rather than a CSV-shaped placeholder.
# @timeout: 120
# @tags: usage, csv, xlsx, ooxml
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
id,name
1,alice
2,bob
3,carol
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"NUMERIC","name":"id","label":"ID"},{"type":"STRING","name":"name","label":"Name"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/mid.dta"
readstat "$tmpdir/mid.dta" "$tmpdir/out.xlsx"

# A valid OOXML package starts with the ZIP local-file-header magic 'PK\x03\x04'.
head -c 4 "$tmpdir/out.xlsx" >"$tmpdir/magic"
python3 - "$tmpdir/magic" <<'PY'
import sys
data = open(sys.argv[1], 'rb').read()
assert data == b'PK\x03\x04', f'expected ZIP local-file magic PK\\x03\\x04, got {data!r}'
PY

# Every OOXML package must contain a [Content_Types].xml part at the package root.
unzip -l "$tmpdir/out.xlsx" >"$tmpdir/listing"
validator_assert_contains "$tmpdir/listing" '[Content_Types].xml'
