#!/usr/bin/env bash
# @testcase: usage-readstat-csv-quoted-header-no-spaces
# @title: readstat CSV with quoted column names that fit DTA naming roundtrips cleanly
# @description: Builds a CSV whose header row uses quoted column names that still fit DTA naming rules (no spaces, no special characters), converts through DTA, and verifies the quotes are stripped from the stored variable names while the data rows survive the round trip with the un-quoted column names in the readback header.
# @timeout: 180
# @tags: usage, csv, header, quoted
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
"first_name","last_name","score"
alice,smith,42
bob,jones,7
carol,davis,33
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"STRING","name":"first_name","label":"First"},{"type":"STRING","name":"last_name","label":"Last"},{"type":"NUMERIC","name":"score","label":"Score"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"
readstat "$tmpdir/out.dta" - >"$tmpdir/out.csv"

# Readback header must carry the un-quoted column names back inside CSV quotes.
header=$(sed -n '1p' "$tmpdir/out.csv")
[[ "$header" == '"first_name","last_name","score"' ]] || {
  printf 'unexpected header on readback: %s\n' "$header" >&2
  exit 1
}

# Header must not contain doubled quotes that would indicate the quoting
# survived literally into the variable name.
if grep -E '""' "$tmpdir/out.csv" >/dev/null; then
  printf 'unexpected doubled quotes in readback\n' >&2
  cat "$tmpdir/out.csv" >&2
  exit 1
fi

validator_assert_contains "$tmpdir/out.csv" '"alice","smith",42.000000'
validator_assert_contains "$tmpdir/out.csv" '"bob","jones",7.000000'
validator_assert_contains "$tmpdir/out.csv" '"carol","davis",33.000000'

readstat "$tmpdir/out.dta" >"$tmpdir/summary"
validator_assert_contains "$tmpdir/summary" 'Columns: 3'
validator_assert_contains "$tmpdir/summary" 'Rows: 3'
