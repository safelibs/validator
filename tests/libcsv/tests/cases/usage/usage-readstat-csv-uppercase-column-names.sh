#!/usr/bin/env bash
# @testcase: usage-readstat-csv-uppercase-column-names
# @title: readstat all-uppercase column names preserve case
# @description: Converts a CSV whose header row uses fully uppercase column names through DTA and verifies the readback emits the column names in the same all-uppercase form, locking in that readstat does not lowercase or normalize the casing.
# @timeout: 180
# @tags: usage, csv, header, case
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
NAME,SCORE,GROUP
alpha,1,A
beta,2,B
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"STRING","name":"NAME","label":"Name"},{"type":"NUMERIC","name":"SCORE","label":"Score"},{"type":"STRING","name":"GROUP","label":"Group"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"
readstat "$tmpdir/out.dta" - >"$tmpdir/out.csv"

# Casing must be preserved verbatim.
header=$(head -n 1 "$tmpdir/out.csv")
[[ "$header" == '"NAME","SCORE","GROUP"' ]] || {
  printf 'header lost case: %s\n' "$header" >&2
  exit 1
}

# And lowercased forms must not appear in the header.
if grep -E '"name"|"score"|"group"' <(printf '%s\n' "$header") >/dev/null; then
  printf 'header was lowercased: %s\n' "$header" >&2
  exit 1
fi

validator_assert_contains "$tmpdir/out.csv" '"alpha",1.000000,"A"'
validator_assert_contains "$tmpdir/out.csv" '"beta",2.000000,"B"'

readstat "$tmpdir/out.dta" >"$tmpdir/summary"
validator_assert_contains "$tmpdir/summary" 'Columns: 3'
validator_assert_contains "$tmpdir/summary" 'Rows: 2'
