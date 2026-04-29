#!/usr/bin/env bash
# @testcase: usage-readstat-dta-leading-space-note
# @title: readstat DTA leading space note
# @description: Exercises readstat dta leading space note through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-readstat-dta-leading-space-note"
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
alpha,1,"  padded note  ",A,10
CSV
convert_and_dump dta
validator_assert_contains "$tmpdir/out.csv" 'padded note'
