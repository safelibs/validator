#!/usr/bin/env bash
# @testcase: usage-readstat-sav-unicode-string
# @title: readstat SAV Unicode string
# @description: Converts a CSV containing Unicode text to SAV with readstat and verifies the decoded string survives the round trip.
# @timeout: 180
# @tags: usage, csv, readstat
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-readstat-sav-unicode-string"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
name
café
CSV
cat >"$tmpdir/meta.json" <<'JSON'
{"type":"SPSS","variables":[{"type":"STRING","name":"name","label":"Name"}]}
JSON
readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.sav"
readstat "$tmpdir/out.sav" - >"$tmpdir/out.csv"
validator_assert_contains "$tmpdir/out.csv" 'café'
