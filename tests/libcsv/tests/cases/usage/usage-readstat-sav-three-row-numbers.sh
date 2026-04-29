#!/usr/bin/env bash
# @testcase: usage-readstat-sav-three-row-numbers
# @title: readstat SAV three row numbers
# @description: Converts three numeric rows to SAV with readstat and verifies all three formatted decimal values appear in the output CSV.
# @timeout: 180
# @tags: usage, csv, readstat
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-readstat-sav-three-row-numbers"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
value
1
2
3
CSV
cat >"$tmpdir/meta.json" <<'JSON'
{"type":"SPSS","variables":[{"type":"NUMERIC","name":"value","label":"Value"}]}
JSON
readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.sav"
readstat "$tmpdir/out.sav" - >"$tmpdir/out.csv"
validator_assert_contains "$tmpdir/out.csv" '1.000000'
validator_assert_contains "$tmpdir/out.csv" '2.000000'
validator_assert_contains "$tmpdir/out.csv" '3.000000'
