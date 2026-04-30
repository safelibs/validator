#!/usr/bin/env bash
# @testcase: usage-readstat-csv-to-xpt-roundtrip
# @title: readstat CSV to SAS XPORT round trip
# @description: Converts CSV through DTA into a SAS transport (XPT) file and verifies the values survive the round trip back to CSV.
# @timeout: 180
# @tags: usage, csv, xpt
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
name,score
alpha,42
beta,7
gamma,9
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"STRING","name":"name","label":"Name"},{"type":"NUMERIC","name":"score","label":"Score"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/mid.dta"
readstat "$tmpdir/mid.dta" "$tmpdir/out.xpt"
validator_require_file "$tmpdir/out.xpt"
readstat "$tmpdir/out.xpt" - >"$tmpdir/out.csv"

validator_assert_contains "$tmpdir/out.csv" '"name","score"'
validator_assert_contains "$tmpdir/out.csv" '"alpha",42.000000'
validator_assert_contains "$tmpdir/out.csv" '"beta",7.000000'
validator_assert_contains "$tmpdir/out.csv" '"gamma",9.000000'

data_rows=$(grep -c '^"' "$tmpdir/out.csv")
[[ "$data_rows" == "4" ]] || {
  printf 'expected 4 lines (header + 3 rows) in %s, got %s\n' "$tmpdir/out.csv" "$data_rows" >&2
  cat "$tmpdir/out.csv" >&2
  exit 1
}
