#!/usr/bin/env bash
# @testcase: usage-readstat-csv-to-sav
# @title: readstat CSV to SAV
# @description: Runs readstat to parse CSV through metadata and write an SPSS SAV dataset.
# @timeout: 180
# @tags: usage, csv
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

workload="csv-to-sav"
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
readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.sav"
readstat "$tmpdir/out.sav" - | tee "$tmpdir/out.csv"
validator_assert_contains "$tmpdir/out.csv" '"alpha",42.000000'
