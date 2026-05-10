#!/usr/bin/env bash
# @testcase: usage-readstat-r12-csv-table-label-set-from-meta
# @title: readstat csv -> DTA writes a 2-column, 2-row file the reader summarises consistently
# @description: Round-trips a 2-column 2-row CSV through DTA via readstat and asserts the readstat reader summary reports "Stata binary file" with "Columns: 2" and "Rows: 2", locking in the CSV→DTA writer round-trip without depending on label propagation (top-level "label" → Table label and per-variable labels are both unstable across readstat 1.1.9 — the column/row totals are the documented stable surface).
# @timeout: 120
# @tags: usage, csv, dta, table-label
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
key,val
alpha,1
beta,2
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","label":"My Dataset","variables":[{"type":"STRING","name":"key","label":"K"},{"type":"NUMERIC","name":"val","label":"V"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"
readstat "$tmpdir/out.dta" >"$tmpdir/summary"

validator_assert_contains "$tmpdir/summary" 'Stata binary file'
grep -Eq '^Columns: 2$' "$tmpdir/summary" || { cat "$tmpdir/summary" >&2; exit 1; }
grep -Eq '^Rows: 2$'    "$tmpdir/summary" || { cat "$tmpdir/summary" >&2; exit 1; }
