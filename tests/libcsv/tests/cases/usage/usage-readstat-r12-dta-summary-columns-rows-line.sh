#!/usr/bin/env bash
# @testcase: usage-readstat-r12-dta-summary-columns-rows-line
# @title: readstat DTA summary reports Columns: 3 and Rows: 4 for a 4x3 input
# @description: Builds a 4-row 3-column DTA from CSV and asserts the readstat summary contains the precise "Columns: 3" and "Rows: 4" lines, locking in the count-line shape of the metadata view for a known-shape file.
# @timeout: 60
# @tags: usage, csv, dta, summary, shape
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
id,name,score
1,alice,10
2,bob,20
3,carol,30
4,dave,40
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"NUMERIC","name":"id","label":"ID"},{"type":"STRING","name":"name","label":"Name"},{"type":"NUMERIC","name":"score","label":"S"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"
readstat "$tmpdir/out.dta" >"$tmpdir/summary"

grep -E '^Columns: 3$' "$tmpdir/summary" >/dev/null || { cat "$tmpdir/summary" >&2; exit 1; }
grep -E '^Rows: 4$' "$tmpdir/summary" >/dev/null || { cat "$tmpdir/summary" >&2; exit 1; }
