#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

case "$case_id" in
  usage-readstat-dta-three-row-numbers)
    cat >"$tmpdir/in.csv" <<'CSV'
value
1
2
3
CSV
    cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"NUMERIC","name":"value","label":"Value"}]}
JSON
    readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"
    readstat "$tmpdir/out.dta" - >"$tmpdir/out.csv"
    validator_assert_contains "$tmpdir/out.csv" '1.000000'
    validator_assert_contains "$tmpdir/out.csv" '2.000000'
    validator_assert_contains "$tmpdir/out.csv" '3.000000'
    ;;
  usage-readstat-sav-three-row-numbers)
    cat >"$tmpdir/in.csv" <<'CSV'
value
1
2
3
CSV
    cat >"$tmpdir/meta.json" <<'JSON'
{"type":"SPSS","variables":[{"type":"NUMERIC","name":"value","label":"Value"}]}
JSON
    readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.sav"
    readstat "$tmpdir/out.sav" - >"$tmpdir/out.csv"
    validator_assert_contains "$tmpdir/out.csv" '1.000000'
    validator_assert_contains "$tmpdir/out.csv" '2.000000'
    validator_assert_contains "$tmpdir/out.csv" '3.000000'
    ;;
  usage-readstat-dta-two-column-summary)
    cat >"$tmpdir/in.csv" <<'CSV'
name,value
alpha,1
beta,2
CSV
    cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"STRING","name":"name","label":"Name"},{"type":"NUMERIC","name":"value","label":"Value"}]}
JSON
    readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"
    readstat "$tmpdir/out.dta" >"$tmpdir/summary"
    validator_assert_contains "$tmpdir/summary" 'Columns: 2'
    ;;
  usage-readstat-sav-two-column-summary)
    cat >"$tmpdir/in.csv" <<'CSV'
name,value
alpha,1
beta,2
CSV
    cat >"$tmpdir/meta.json" <<'JSON'
{"type":"SPSS","variables":[{"type":"STRING","name":"name","label":"Name"},{"type":"NUMERIC","name":"value","label":"Value"}]}
JSON
    readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.sav"
    readstat "$tmpdir/out.sav" >"$tmpdir/summary"
    validator_assert_contains "$tmpdir/summary" 'Columns: 2'
    ;;
  usage-readstat-dta-quoted-comma-string)
    cat >"$tmpdir/in.csv" <<'CSV'
note
"alpha, beta"
CSV
    cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"STRING","name":"note","label":"Note"}]}
JSON
    readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"
    readstat "$tmpdir/out.dta" - >"$tmpdir/out.csv"
    validator_assert_contains "$tmpdir/out.csv" 'alpha, beta'
    ;;
  usage-readstat-sav-quoted-comma-string)
    cat >"$tmpdir/in.csv" <<'CSV'
note
"alpha, beta"
CSV
    cat >"$tmpdir/meta.json" <<'JSON'
{"type":"SPSS","variables":[{"type":"STRING","name":"note","label":"Note"}]}
JSON
    readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.sav"
    readstat "$tmpdir/out.sav" - >"$tmpdir/out.csv"
    validator_assert_contains "$tmpdir/out.csv" 'alpha, beta'
    ;;
  usage-readstat-dta-large-positive-number)
    cat >"$tmpdir/in.csv" <<'CSV'
value
123456
CSV
    cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"NUMERIC","name":"value","label":"Value"}]}
JSON
    readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"
    readstat "$tmpdir/out.dta" - >"$tmpdir/out.csv"
    validator_assert_contains "$tmpdir/out.csv" '123456.000000'
    ;;
  usage-readstat-sav-large-positive-number)
    cat >"$tmpdir/in.csv" <<'CSV'
value
123456
CSV
    cat >"$tmpdir/meta.json" <<'JSON'
{"type":"SPSS","variables":[{"type":"NUMERIC","name":"value","label":"Value"}]}
JSON
    readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.sav"
    readstat "$tmpdir/out.sav" - >"$tmpdir/out.csv"
    validator_assert_contains "$tmpdir/out.csv" '123456.000000'
    ;;
  usage-readstat-dta-empty-string-row)
    printf 'note\n""\n' >"$tmpdir/in.csv"
    cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"STRING","name":"note","label":"Note"}]}
JSON
    readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"
    readstat "$tmpdir/out.dta" >"$tmpdir/summary"
    validator_assert_contains "$tmpdir/summary" 'Columns: 1'
    ;;
  usage-readstat-sav-empty-string-row)
    printf 'note\n""\n' >"$tmpdir/in.csv"
    cat >"$tmpdir/meta.json" <<'JSON'
{"type":"SPSS","variables":[{"type":"STRING","name":"note","label":"Note"}]}
JSON
    readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.sav"
    readstat "$tmpdir/out.sav" >"$tmpdir/summary"
    validator_assert_contains "$tmpdir/summary" 'Columns: 1'
    ;;
  *)
    printf 'unknown libcsv tenth-batch usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
