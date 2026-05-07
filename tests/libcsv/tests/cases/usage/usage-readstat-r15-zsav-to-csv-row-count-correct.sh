#!/usr/bin/env bash
# @testcase: usage-readstat-r15-zsav-to-csv-row-count-correct
# @title: readstat zsav-to-csv conversion emits exactly the source row count plus a header
# @description: Round-trips a 5-row CSV through DTA into ZSAV, then converts the ZSAV back to CSV via stdout and asserts the resulting CSV has exactly 6 lines (1 header + 5 data rows) — locking in that the binary-compressed SPSS read path correctly enumerates all rows on Ubuntu 24.04 readstat 1.1.9, despite ZSAV summary metadata expressing the rows differently from DTA.
# @timeout: 120
# @tags: usage, csv, zsav, conversion, rows
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
readstat "$tmpdir/mid.dta" "$tmpdir/out.zsav"
readstat "$tmpdir/out.zsav" - >"$tmpdir/out.csv"

# Header line plus 5 data rows.
line_count=$(wc -l <"$tmpdir/out.csv")
[[ "$line_count" == "6" ]] || {
  printf 'ZSAV->CSV expected 6 lines, got %s\n' "$line_count" >&2
  cat "$tmpdir/out.csv" >&2
  exit 1
}
validator_assert_contains "$tmpdir/out.csv" '"id","score"'
