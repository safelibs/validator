#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
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

case "$case_id" in
  usage-readstat-dta-three-rows)
    cat >"$tmpdir/in.csv" <<'CSV'
name,score,note,group,count
alpha,1,first,A,10
beta,2,second,B,20
gamma,3,third,C,30
CSV
    convert_and_dump dta
    validator_assert_contains "$tmpdir/out.csv" '"gamma",3.000000,"third","C",30.000000'
    ;;
  usage-readstat-sav-long-string)
    cat >"$tmpdir/in.csv" <<'CSV'
name,score,note,group,count
alpha,1,this is a longer string value,A,10
CSV
    convert_and_dump sav
    validator_assert_contains "$tmpdir/out.csv" 'this is a longer string value'
    ;;
  usage-readstat-dta-negative-number)
    cat >"$tmpdir/in.csv" <<'CSV'
name,score,note,group,count
alpha,-7,negative,A,1
CSV
    convert_and_dump dta
    validator_assert_contains "$tmpdir/out.csv" '"alpha",-7.000000'
    ;;
  usage-readstat-sav-decimal-number)
    cat >"$tmpdir/in.csv" <<'CSV'
name,score,note,group,count
alpha,3.5,decimal,A,1
CSV
    convert_and_dump sav
    validator_assert_contains "$tmpdir/out.csv" '3.500000'
    ;;
  usage-readstat-csv-empty-string)
    cat >"$tmpdir/in.csv" <<'CSV'
name,score,note,group,count
alpha,1,,A,1
CSV
    convert_and_dump dta
    validator_assert_contains "$tmpdir/out.csv" '"alpha",1.000000,'
    ;;
  usage-readstat-dta-column-count)
    cat >"$tmpdir/in.csv" <<'CSV'
name,score,note,group,count
alpha,1,first,A,10
CSV
    write_meta
    readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"
    readstat "$tmpdir/out.dta" >"$tmpdir/summary"
    validator_assert_contains "$tmpdir/summary" 'Columns: 5'
    ;;
  usage-readstat-sav-row-count)
    cat >"$tmpdir/in.csv" <<'CSV'
name,score,note,group,count
alpha,1,first,A,10
beta,2,second,B,20
gamma,3,third,C,30
delta,4,fourth,D,40
CSV
    write_meta
    readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.sav"
    readstat "$tmpdir/out.sav" >"$tmpdir/summary"
    validator_assert_contains "$tmpdir/summary" 'Rows: 4'
    ;;
  usage-readstat-dta-spaced-value)
    cat >"$tmpdir/in.csv" <<'CSV'
name,score,note,group,count
alpha,1,space separated words,A,10
CSV
    convert_and_dump dta
    validator_assert_contains "$tmpdir/out.csv" 'space separated words'
    ;;
  usage-readstat-sav-comma-value)
    cat >"$tmpdir/in.csv" <<'CSV'
name,score,note,group,count
alpha,1,"comma, inside",A,10
CSV
    convert_and_dump sav
    validator_assert_contains "$tmpdir/out.csv" '"comma, inside"'
    ;;
  usage-readstat-dta-zero-value)
    cat >"$tmpdir/in.csv" <<'CSV'
name,score,note,group,count
zero,0,zero,A,0
CSV
    convert_and_dump dta
    validator_assert_contains "$tmpdir/out.csv" '"zero",0.000000'
    ;;
  *)
    printf 'unknown libcsv extra usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
