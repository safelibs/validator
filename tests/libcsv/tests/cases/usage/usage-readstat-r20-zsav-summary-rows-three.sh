#!/usr/bin/env bash
# @testcase: usage-readstat-r20-zsav-summary-rows-three
# @title: readstat summary of a three-row ZSAV (via DTA) reports Rows: 3
# @description: Builds a CSV with three data rows, converts to .dta via Stata metadata, then converts the .dta to .zsav, captures the summary output, and asserts it contains the literal "Rows: 3" - locking in row-count summary reporting on the compressed SAV (ZSAV) writer path via the DTA intermediate.
# @timeout: 60
# @tags: usage, zsav, summary, rows, r20
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
v
3
6
9
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"NUMERIC","name":"v","label":"V"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/mid.dta"
readstat "$tmpdir/mid.dta" "$tmpdir/out.zsav"
readstat "$tmpdir/out.zsav" >"$tmpdir/summary"

validator_assert_contains "$tmpdir/summary" 'Rows: 3'
