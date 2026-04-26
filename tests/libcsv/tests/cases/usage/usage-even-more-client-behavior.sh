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
  usage-readstat-dta-leading-space-note)
    cat >"$tmpdir/in.csv" <<'CSV'
name,score,note,group,count
alpha,1,"  padded note  ",A,10
CSV
    convert_and_dump dta
    validator_assert_contains "$tmpdir/out.csv" 'padded note'
    ;;
  usage-readstat-sav-leading-space-note)
    cat >"$tmpdir/in.csv" <<'CSV'
name,score,note,group,count
alpha,1,"  padded note  ",A,10
CSV
    convert_and_dump sav
    validator_assert_contains "$tmpdir/out.csv" 'padded note'
    ;;
  usage-readstat-dta-pipe-note)
    cat >"$tmpdir/in.csv" <<'CSV'
name,score,note,group,count
alpha,1,alpha|beta|gamma,A,10
CSV
    convert_and_dump dta
    validator_assert_contains "$tmpdir/out.csv" 'alpha|beta|gamma'
    ;;
  usage-readstat-sav-pipe-note)
    cat >"$tmpdir/in.csv" <<'CSV'
name,score,note,group,count
alpha,1,alpha|beta|gamma,A,10
CSV
    convert_and_dump sav
    validator_assert_contains "$tmpdir/out.csv" 'alpha|beta|gamma'
    ;;
  usage-readstat-dta-count-sum)
    cat >"$tmpdir/in.csv" <<'CSV'
name,score,note,group,count
alpha,1,first,A,10
beta,2,second,B,20
gamma,3,third,C,30
CSV
    convert_and_dump dta
    awk -F, 'NR > 1 {gsub(/"/, "", $5); sum += $5} END {print sum}' "$tmpdir/out.csv" >"$tmpdir/out"
    grep -Fxq '60' "$tmpdir/out"
    ;;
  usage-readstat-sav-count-sum)
    cat >"$tmpdir/in.csv" <<'CSV'
name,score,note,group,count
alpha,1,first,A,10
beta,2,second,B,20
gamma,3,third,C,30
CSV
    convert_and_dump sav
    awk -F, 'NR > 1 {gsub(/"/, "", $5); sum += $5} END {print sum}' "$tmpdir/out.csv" >"$tmpdir/out"
    grep -Fxq '60' "$tmpdir/out"
    ;;
  usage-readstat-dta-mixed-group)
    cat >"$tmpdir/in.csv" <<'CSV'
name,score,note,group,count
alpha,1,first,A-1,10
CSV
    convert_and_dump dta
    validator_assert_contains "$tmpdir/out.csv" 'A-1'
    ;;
  usage-readstat-sav-mixed-group)
    cat >"$tmpdir/in.csv" <<'CSV'
name,score,note,group,count
alpha,1,first,A-1,10
CSV
    convert_and_dump sav
    validator_assert_contains "$tmpdir/out.csv" 'A-1'
    ;;
  usage-readstat-dta-summary-single-row)
    cat >"$tmpdir/in.csv" <<'CSV'
name,score,note,group,count
alpha,1,first,A,10
CSV
    write_meta
    readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"
    readstat "$tmpdir/out.dta" >"$tmpdir/summary"
    validator_assert_contains "$tmpdir/summary" 'Rows: 1'
    ;;
  usage-readstat-sav-summary-single-row)
    cat >"$tmpdir/in.csv" <<'CSV'
name,score,note,group,count
alpha,1,first,A,10
CSV
    write_meta
    readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.sav"
    readstat "$tmpdir/out.sav" >"$tmpdir/summary"
    validator_assert_contains "$tmpdir/summary" 'Rows: 1'
    ;;
  *)
    printf 'unknown libcsv even-more usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
