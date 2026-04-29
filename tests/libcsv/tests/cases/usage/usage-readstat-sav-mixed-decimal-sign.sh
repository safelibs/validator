#!/usr/bin/env bash
# @testcase: usage-readstat-sav-mixed-decimal-sign
# @title: readstat SAV mixed decimal sign
# @description: Converts signed decimal numbers to SAV with readstat and verifies both formatted values in the output CSV.
# @timeout: 180
# @tags: usage, csv, readstat
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-readstat-sav-mixed-decimal-sign"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
value
-1.5
2.75
CSV
cat >"$tmpdir/meta.json" <<'JSON'
{"type":"SPSS","variables":[{"type":"NUMERIC","name":"value","label":"Value"}]}
JSON
readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.sav"
readstat "$tmpdir/out.sav" - >"$tmpdir/out.csv"
validator_assert_contains "$tmpdir/out.csv" '-1.500000'
validator_assert_contains "$tmpdir/out.csv" '2.750000'
