#!/usr/bin/env bash
# @testcase: usage-readstat-r13-csv-to-dta-multi-row-csv-readback-line-count
# @title: readstat DTA-to-CSV stdout dump emits exactly N+1 lines for N data rows
# @description: Round-trips a 7-row 2-column CSV through DTA, dumps the DTA back to CSV via the dash stdout target, and asserts the resulting stdout contains exactly 8 newline-terminated lines (one header + seven data rows), pinning the line-count contract of the CSV-to-stdout dump path for a known shape.
# @timeout: 60
# @tags: usage, csv, dta, line-count
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
id,name
1,alice
2,bob
3,carol
4,dave
5,eve
6,frank
7,grace
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"NUMERIC","name":"id","label":"ID"},{"type":"STRING","name":"name","label":"Name"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/mid.dta"
readstat "$tmpdir/mid.dta" - >"$tmpdir/out.csv"

count=$(wc -l <"$tmpdir/out.csv")
[[ "$count" == "8" ]] || {
  printf 'expected 8 lines in CSV stdout dump, got %s\n' "$count" >&2
  cat "$tmpdir/out.csv" >&2
  exit 1
}
# The header must be the first line.
head -1 "$tmpdir/out.csv" >"$tmpdir/header"
validator_assert_contains "$tmpdir/header" '"id","name"'
# All seven names must appear in the body.
for n in alice bob carol dave eve frank grace; do
  validator_assert_contains "$tmpdir/out.csv" "\"$n\""
done
