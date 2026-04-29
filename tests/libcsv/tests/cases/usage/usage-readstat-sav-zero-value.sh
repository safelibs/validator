#!/usr/bin/env bash
# @testcase: usage-readstat-sav-zero-value
# @title: readstat SAV zero value
# @description: Converts a zero numeric field through SAV and verifies the zero value is preserved.
# @timeout: 180
# @tags: usage, csv
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-readstat-sav-zero-value"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

write_meta() {
  cat >"$tmpdir/meta.json" <<'JSON'
{"type":"SPSS","variables":[{"type":"STRING","name":"name","label":"Name"},{"type":"NUMERIC","name":"score","label":"Score"},{"type":"STRING","name":"note","label":"Note"},{"type":"STRING","name":"group","label":"Group"},{"type":"NUMERIC","name":"count","label":"Count"}]}
JSON
}

convert_and_dump() {
  local ext=$1
  write_meta
  readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.$ext"
  readstat "$tmpdir/out.$ext" - >"$tmpdir/out.csv"
}

cat >"$tmpdir/in.csv" <<'CSV'
name,score,note,group,count
zero,0,zero,A,0
CSV
convert_and_dump sav
validator_assert_contains "$tmpdir/out.csv" '"zero",0.000000'
