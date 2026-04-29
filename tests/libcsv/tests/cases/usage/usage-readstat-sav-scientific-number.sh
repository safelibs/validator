#!/usr/bin/env bash
# @testcase: usage-readstat-sav-scientific-number
# @title: readstat SAV scientific number
# @description: Converts a scientific-notation numeric CSV field to SAV with readstat and verifies the normalized numeric output.
# @timeout: 180
# @tags: usage, csv, readstat
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-readstat-sav-scientific-number"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
value
1.25e3
CSV
cat >"$tmpdir/meta.json" <<'JSON'
{"type":"SPSS","variables":[{"type":"NUMERIC","name":"value","label":"Value"}]}
JSON
readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.sav"
readstat "$tmpdir/out.sav" - >"$tmpdir/out.csv"
validator_assert_contains "$tmpdir/out.csv" '1250.000000'
