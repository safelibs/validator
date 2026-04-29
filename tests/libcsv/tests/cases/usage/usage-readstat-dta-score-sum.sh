#!/usr/bin/env bash
# @testcase: usage-readstat-dta-score-sum
# @title: readstat DTA score sum
# @description: Converts multiple CSV rows through DTA and verifies numeric score aggregation over the exported data.
# @timeout: 180
# @tags: usage, csv
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-readstat-dta-score-sum"
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

write_three_rows_csv
convert_and_dump dta
awk -F, 'NR > 1 {gsub(/"/, "", $2); sum += $2} END {print sum}' "$tmpdir/out.csv" >"$tmpdir/sum"
grep -Fxq '6' "$tmpdir/sum"
