#!/usr/bin/env bash
# @testcase: usage-readstat-sav-row-order
# @title: readstat SAV row order
# @description: Converts multiple CSV rows through SAV and verifies row ordering is preserved in exported data.
# @timeout: 180
# @tags: usage, csv
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-readstat-sav-row-order"
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
convert_and_dump sav
second=$(sed -n '2p' "$tmpdir/out.csv")
third=$(sed -n '3p' "$tmpdir/out.csv")
case "$second" in
  '"alpha",1.000000,"first","A",10.000000') ;;
  *) printf 'unexpected second SAV row: %s\n' "$second" >&2; exit 1 ;;
esac
case "$third" in
  '"beta",2.000000,"second","B",20.000000') ;;
  *) printf 'unexpected third SAV row: %s\n' "$third" >&2; exit 1 ;;
esac
