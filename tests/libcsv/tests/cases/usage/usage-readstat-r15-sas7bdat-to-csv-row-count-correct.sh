#!/usr/bin/env bash
# @testcase: usage-readstat-r15-sas7bdat-to-csv-row-count-correct
# @title: readstat sas7bdat-to-csv conversion emits exactly the source row count plus a header
# @description: Round-trips a 5-row CSV through DTA into SAS7BDAT, then converts the SAS7BDAT back to CSV via stdout and asserts the resulting CSV has exactly 6 lines (1 header + 5 data rows) — locking in that the SAS7BDAT read path enumerates all rows correctly on Ubuntu 24.04 readstat 1.1.9, distinct from XPT (which reports -1 in summary but still enumerates rows) and SAV/ZSAV roundtrips.
# @timeout: 120
# @tags: usage, csv, sas7bdat, conversion, rows
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
id,score
1,10
2,20
3,30
4,40
5,50
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"NUMERIC","name":"id","label":"ID"},{"type":"NUMERIC","name":"score","label":"Score"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/mid.dta"
readstat "$tmpdir/mid.dta" "$tmpdir/out.sas7bdat"
readstat "$tmpdir/out.sas7bdat" - >"$tmpdir/out.csv"

line_count=$(wc -l <"$tmpdir/out.csv")
[[ "$line_count" == "6" ]] || {
  printf 'SAS7BDAT->CSV expected 6 lines, got %s\n' "$line_count" >&2
  cat "$tmpdir/out.csv" >&2
  exit 1
}
validator_assert_contains "$tmpdir/out.csv" '"id","score"'
