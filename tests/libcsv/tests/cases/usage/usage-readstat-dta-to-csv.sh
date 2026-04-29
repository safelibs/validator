#!/usr/bin/env bash
# @testcase: usage-readstat-dta-to-csv
# @title: readstat DTA to CSV
# @description: Runs readstat to convert a CSV-derived DTA dataset back to CSV and verifies row values.
# @timeout: 180
# @tags: usage, csv
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

workload="dta-to-csv"
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

write_basic_csv
write_metadata
readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"
readstat "$tmpdir/out.dta" "$tmpdir/from-dta.csv"
validator_assert_contains "$tmpdir/from-dta.csv" '"beta",7.000000'
