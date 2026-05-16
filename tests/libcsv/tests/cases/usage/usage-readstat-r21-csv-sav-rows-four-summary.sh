#!/usr/bin/env bash
# @testcase: usage-readstat-r21-csv-sav-rows-four-summary
# @title: readstat summary of a four-row SAV converted from CSV reports Rows: 4
# @description: Builds a four-row CSV with SPSS metadata, converts to .sav directly (skipping the DTA intermediate), captures the summary, and asserts it contains "Rows: 4" - locking in row-count summary reporting on the direct CSV-to-SAV writer path with four data rows specifically.
# @timeout: 60
# @tags: usage, sav, summary, rows, r21
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
v
1
2
3
4
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"SPSS","variables":[{"type":"NUMERIC","name":"v","label":"V"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.sav"
readstat "$tmpdir/out.sav" >"$tmpdir/summary"

validator_assert_contains "$tmpdir/summary" 'Rows: 4'
