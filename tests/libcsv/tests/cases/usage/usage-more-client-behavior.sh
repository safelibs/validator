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

write_three_rows_csv() {
  cat >"$tmpdir/in.csv" <<'CSV'
name,score,note,group,count
alpha,1,first,A,10
beta,2,second,B,20
gamma,3,third,C,30
CSV
}

case "$case_id" in
  usage-readstat-dta-header-fields)
    write_three_rows_csv
    convert_and_dump dta
    header=$(sed -n '1p' "$tmpdir/out.csv")
    case "$header" in
      '"name","score","note","group","count"') ;;
      *) printf 'unexpected DTA header: %s\n' "$header" >&2; exit 1 ;;
    esac
    ;;
  usage-readstat-sav-header-fields)
    write_three_rows_csv
    convert_and_dump sav
    header=$(sed -n '1p' "$tmpdir/out.csv")
    case "$header" in
      '"name","score","note","group","count"') ;;
      *) printf 'unexpected SAV header: %s\n' "$header" >&2; exit 1 ;;
    esac
    ;;
  usage-readstat-dta-leading-zero-string)
    cat >"$tmpdir/in.csv" <<'CSV'
name,score,note,group,count
00123,1,leading zero,A,10
CSV
    convert_and_dump dta
    validator_assert_contains "$tmpdir/out.csv" '"00123",1.000000'
    ;;
  usage-readstat-sav-leading-zero-string)
    cat >"$tmpdir/in.csv" <<'CSV'
name,score,note,group,count
00123,1,leading zero,A,10
CSV
    convert_and_dump sav
    validator_assert_contains "$tmpdir/out.csv" '"00123",1.000000'
    ;;
  usage-readstat-dta-slash-note)
    cat >"$tmpdir/in.csv" <<'CSV'
name,score,note,group,count
alpha,1,path/value,A,10
CSV
    convert_and_dump dta
    validator_assert_contains "$tmpdir/out.csv" 'path/value'
    ;;
  usage-readstat-sav-slash-note)
    cat >"$tmpdir/in.csv" <<'CSV'
name,score,note,group,count
alpha,1,path/value,A,10
CSV
    convert_and_dump sav
    validator_assert_contains "$tmpdir/out.csv" 'path/value'
    ;;
  usage-readstat-dta-score-sum)
    write_three_rows_csv
    convert_and_dump dta
    awk -F, 'NR > 1 {gsub(/"/, "", $2); sum += $2} END {print sum}' "$tmpdir/out.csv" >"$tmpdir/sum"
    grep -Fxq '6' "$tmpdir/sum"
    ;;
  usage-readstat-sav-score-sum)
    write_three_rows_csv
    convert_and_dump sav
    awk -F, 'NR > 1 {gsub(/"/, "", $2); sum += $2} END {print sum}' "$tmpdir/out.csv" >"$tmpdir/sum"
    grep -Fxq '6' "$tmpdir/sum"
    ;;
  usage-readstat-dta-row-order)
    write_three_rows_csv
    convert_and_dump dta
    second=$(sed -n '2p' "$tmpdir/out.csv")
    third=$(sed -n '3p' "$tmpdir/out.csv")
    case "$second" in
      '"alpha",1.000000,"first","A",10.000000') ;;
      *) printf 'unexpected second DTA row: %s\n' "$second" >&2; exit 1 ;;
    esac
    case "$third" in
      '"beta",2.000000,"second","B",20.000000') ;;
      *) printf 'unexpected third DTA row: %s\n' "$third" >&2; exit 1 ;;
    esac
    ;;
  usage-readstat-sav-row-order)
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
    ;;
  *)
    printf 'unknown libcsv additional usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
