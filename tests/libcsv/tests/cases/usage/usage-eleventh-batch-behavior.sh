#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

write_meta() {
  local type=$1
  cat >"$tmpdir/meta.json" <<JSON
{"type":"$type","variables":[{"type":"STRING","name":"note","label":"Note"},{"type":"NUMERIC","name":"value","label":"Value"}]}
JSON
}

write_string_meta() {
  local type=$1
  cat >"$tmpdir/meta.json" <<JSON
{"type":"$type","variables":[{"type":"STRING","name":"note","label":"Note"}]}
JSON
}

case "$case_id" in
  usage-readstat-dta-double-quote-string-batch11)
    printf 'note\n"alpha ""quoted"""\n' >"$tmpdir/in.csv"
    write_string_meta Stata
    readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"
    readstat "$tmpdir/out.dta" - >"$tmpdir/out.csv"
    validator_assert_contains "$tmpdir/out.csv" '"alpha ""quoted"""'
    ;;
  usage-readstat-sav-double-quote-string-batch11)
    printf 'note\n"alpha ""quoted"""\n' >"$tmpdir/in.csv"
    write_string_meta SPSS
    readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.sav"
    readstat "$tmpdir/out.sav" - >"$tmpdir/out.csv"
    validator_assert_contains "$tmpdir/out.csv" '"alpha ""quoted"""'
    ;;
  usage-readstat-dta-date-string-batch11)
    printf 'note\n2024-06-01\n' >"$tmpdir/in.csv"
    write_string_meta Stata
    readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"
    readstat "$tmpdir/out.dta" - >"$tmpdir/out.csv"
    validator_assert_contains "$tmpdir/out.csv" '2024-06-01'
    ;;
  usage-readstat-sav-date-string-batch11)
    printf 'note\n2024-06-01\n' >"$tmpdir/in.csv"
    write_string_meta SPSS
    readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.sav"
    readstat "$tmpdir/out.sav" - >"$tmpdir/out.csv"
    validator_assert_contains "$tmpdir/out.csv" '2024-06-01'
    ;;
  usage-readstat-dta-small-decimal-batch11)
    printf 'note,value\nsmall,0.125\n' >"$tmpdir/in.csv"
    write_meta Stata
    readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"
    readstat "$tmpdir/out.dta" - >"$tmpdir/out.csv"
    validator_assert_contains "$tmpdir/out.csv" '0.125000'
    ;;
  usage-readstat-sav-small-decimal-batch11)
    printf 'note,value\nsmall,0.125\n' >"$tmpdir/in.csv"
    write_meta SPSS
    readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.sav"
    readstat "$tmpdir/out.sav" - >"$tmpdir/out.csv"
    validator_assert_contains "$tmpdir/out.csv" '0.125000'
    ;;
  usage-readstat-dta-underscore-header-batch11)
    printf 'note_value\nalpha\n' >"$tmpdir/in.csv"
    cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"STRING","name":"note_value","label":"Note Value"}]}
JSON
    readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"
    readstat "$tmpdir/out.dta" >"$tmpdir/summary"
    validator_assert_contains "$tmpdir/summary" 'Columns: 1'
    ;;
  usage-readstat-sav-underscore-header-batch11)
    printf 'note_value\nalpha\n' >"$tmpdir/in.csv"
    cat >"$tmpdir/meta.json" <<'JSON'
{"type":"SPSS","variables":[{"type":"STRING","name":"note_value","label":"Note Value"}]}
JSON
    readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.sav"
    readstat "$tmpdir/out.sav" >"$tmpdir/summary"
    validator_assert_contains "$tmpdir/summary" 'Columns: 1'
    ;;
  usage-readstat-dta-two-string-columns-batch11)
    printf 'left,right\nalpha,beta\n' >"$tmpdir/in.csv"
    cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"STRING","name":"left","label":"Left"},{"type":"STRING","name":"right","label":"Right"}]}
JSON
    readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"
    readstat "$tmpdir/out.dta" - >"$tmpdir/out.csv"
    validator_assert_contains "$tmpdir/out.csv" '"alpha","beta"'
    ;;
  usage-readstat-sav-two-string-columns-batch11)
    printf 'left,right\nalpha,beta\n' >"$tmpdir/in.csv"
    cat >"$tmpdir/meta.json" <<'JSON'
{"type":"SPSS","variables":[{"type":"STRING","name":"left","label":"Left"},{"type":"STRING","name":"right","label":"Right"}]}
JSON
    readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.sav"
    readstat "$tmpdir/out.sav" - >"$tmpdir/out.csv"
    validator_assert_contains "$tmpdir/out.csv" '"alpha","beta"'
    ;;
  *)
    printf 'unknown libcsv eleventh-batch usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
