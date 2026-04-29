#!/usr/bin/env bash
# @testcase: usage-readstat-dta-header-fields
# @title: readstat DTA header fields
# @description: Converts CSV to DTA with readstat and verifies the exported CSV header row preserves the expected field order.
# @timeout: 180
# @tags: usage, csv
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-readstat-dta-header-fields"
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
header=$(sed -n '1p' "$tmpdir/out.csv")
case "$header" in
  '"name","score","note","group","count"') ;;
  *) printf 'unexpected DTA header: %s\n' "$header" >&2; exit 1 ;;
esac
