#!/usr/bin/env bash
# @testcase: usage-readstat-dta-count-sum
# @title: readstat DTA count sum
# @description: Exercises readstat dta count sum through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-readstat-dta-count-sum"
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
alpha,1,first,A,10
beta,2,second,B,20
gamma,3,third,C,30
CSV
convert_and_dump dta
awk -F, 'NR > 1 {gsub(/"/, "", $5); sum += $5} END {print sum}' "$tmpdir/out.csv" >"$tmpdir/out"
grep -Fxq '60' "$tmpdir/out"
