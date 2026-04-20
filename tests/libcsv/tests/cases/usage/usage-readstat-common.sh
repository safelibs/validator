#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

workload=${1:?missing readstat workload}
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

write_basic_csv() {
    cat >"$tmpdir/in.csv" <<'CSV'
name,score
alpha,42
beta,7
CSV
}

write_quoted_csv() {
    cat >"$tmpdir/in.csv" <<'CSV'
name,score
"alpha, one",42
beta,
CSV
}

write_escaped_quotes_csv() {
    cat >"$tmpdir/in.csv" <<'CSV'
name,score
"alpha ""quoted""",42
beta,7
CSV
}

write_wide_csv() {
    cat >"$tmpdir/in.csv" <<'CSV'
name,score,group,note
alpha,42,A,first-row
beta,7,B,fourth-column
CSV
}

write_metadata() {
    cat >"$tmpdir/meta.json" <<'JSON'
{"type":"SPSS","variables":[{"type":"STRING","name":"name","label":"Name"},{"type":"NUMERIC","name":"score","label":"Score","missing":{"type":"DISCRETE","values":[99]}}]}
JSON
}

write_wide_metadata() {
    cat >"$tmpdir/meta.json" <<'JSON'
{"type":"SPSS","variables":[{"type":"STRING","name":"name","label":"Name"},{"type":"NUMERIC","name":"score","label":"Score"},{"type":"STRING","name":"group","label":"Group"},{"type":"STRING","name":"note","label":"Note"}]}
JSON
}

case "$workload" in
    csv-to-dta)
        write_basic_csv
        write_metadata
        readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"
        readstat "$tmpdir/out.dta" - | tee "$tmpdir/out.csv"
        validator_assert_contains "$tmpdir/out.csv" '"alpha",42.000000'
        ;;
    dta-to-csv)
        write_basic_csv
        write_metadata
        readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"
        readstat "$tmpdir/out.dta" "$tmpdir/from-dta.csv"
        validator_assert_contains "$tmpdir/from-dta.csv" '"beta",7.000000'
        ;;
    csv-to-sav)
        write_basic_csv
        write_metadata
        readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.sav"
        readstat "$tmpdir/out.sav" - | tee "$tmpdir/out.csv"
        validator_assert_contains "$tmpdir/out.csv" '"alpha",42.000000'
        ;;
    sav-to-csv)
        write_basic_csv
        write_metadata
        readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.sav"
        readstat "$tmpdir/out.sav" "$tmpdir/from-sav.csv"
        validator_assert_contains "$tmpdir/from-sav.csv" '"beta",7.000000'
        ;;
    metadata-summary)
        write_basic_csv
        write_metadata
        readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"
        readstat "$tmpdir/out.dta" | tee "$tmpdir/summary"
        validator_assert_contains "$tmpdir/summary" 'Columns: 2'
        validator_assert_contains "$tmpdir/summary" 'Rows: 2'
        ;;
    quoted-csv)
        write_quoted_csv
        write_metadata
        readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"
        readstat "$tmpdir/out.dta" - | tee "$tmpdir/out.csv"
        validator_assert_contains "$tmpdir/out.csv" '"alpha, one",42.000000'
        ;;
    missing-values)
        write_quoted_csv
        write_metadata
        readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"
        readstat "$tmpdir/out.dta" - | tee "$tmpdir/out.csv"
        validator_assert_contains "$tmpdir/out.csv" '"beta",'
        ;;
    normalize-csv)
        write_basic_csv
        write_metadata
        readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/normalized.csv"
        validator_assert_contains "$tmpdir/normalized.csv" '"score"'
        validator_assert_contains "$tmpdir/normalized.csv" '42.000000'
        ;;
    escaped-quotes-csv)
        write_escaped_quotes_csv
        write_metadata
        readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"
        readstat "$tmpdir/out.dta" - | tee "$tmpdir/out.csv"
        validator_assert_contains "$tmpdir/out.csv" '"alpha ""quoted""",42.000000'
        ;;
    wide-csv)
        write_wide_csv
        write_wide_metadata
        readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"
        readstat "$tmpdir/out.dta" | tee "$tmpdir/summary"
        validator_assert_contains "$tmpdir/summary" 'Columns: 4'
        readstat "$tmpdir/out.dta" - | tee "$tmpdir/out.csv"
        validator_assert_contains "$tmpdir/out.csv" 'fourth-column'
        ;;
    *)
        printf 'unknown readstat workload: %s\n' "$workload" >&2
        exit 2
        ;;
esac
