#!/usr/bin/env bash
# @testcase: usage-readstat-r19-sav-summary-rows-line
# @title: readstat summary of a four-row SAV reports Rows: 4
# @description: Builds a CSV with four data rows, converts to .sav via SPSS metadata, captures the summary output, and asserts it contains the literal "Rows: 4" - locking in the row-count summary line on the SAV writer path with a row count distinct from existing tests.
# @timeout: 60
# @tags: usage, csv, sav, summary, rows, r19
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
v
11
22
33
44
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"SPSS","variables":[{"type":"NUMERIC","name":"v","label":"V"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.sav"
readstat "$tmpdir/out.sav" >"$tmpdir/summary"

validator_assert_contains "$tmpdir/summary" 'Rows: 4'
