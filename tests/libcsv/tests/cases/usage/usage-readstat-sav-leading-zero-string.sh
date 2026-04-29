#!/usr/bin/env bash
# @testcase: usage-readstat-sav-leading-zero-string
# @title: readstat SAV leading zero string
# @description: Converts a string field with leading zeros through SAV and verifies the leading zeros survive export.
# @timeout: 180
# @tags: usage, csv
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-readstat-sav-leading-zero-string"
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

write_three_rows_csv() {
  cat >"$tmpdir/in.csv" <<'CSV'
name,score,note,group,count
alpha,1,first,A,10
beta,2,second,B,20
gamma,3,third,C,30
CSV
}

cat >"$tmpdir/in.csv" <<'CSV'
name,score,note,group,count
00123,1,leading zero,A,10
CSV
convert_and_dump sav
validator_assert_contains "$tmpdir/out.csv" '"00123",1.000000'
