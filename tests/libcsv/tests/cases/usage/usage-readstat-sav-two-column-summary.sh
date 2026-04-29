#!/usr/bin/env bash
# @testcase: usage-readstat-sav-two-column-summary
# @title: readstat SAV two-column summary
# @description: Converts a two-column CSV to SAV with readstat and verifies the summary reports two columns.
# @timeout: 180
# @tags: usage, csv, readstat
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-readstat-sav-two-column-summary"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
name,value
alpha,1
beta,2
CSV
cat >"$tmpdir/meta.json" <<'JSON'
{"type":"SPSS","variables":[{"type":"STRING","name":"name","label":"Name"},{"type":"NUMERIC","name":"value","label":"Value"}]}
JSON
readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.sav"
readstat "$tmpdir/out.sav" >"$tmpdir/summary"
validator_assert_contains "$tmpdir/summary" 'Columns: 2'
