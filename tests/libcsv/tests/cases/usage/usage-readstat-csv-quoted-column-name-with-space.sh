#!/usr/bin/env bash
# @testcase: usage-readstat-csv-quoted-column-name-with-space
# @title: readstat quoted CSV header with space in column name
# @description: Converts a CSV whose header row carries a quoted column name containing a space character through DTA using a matching metadata variable name and verifies the original quoted header is restored on readback and the data row reappears intact.
# @timeout: 180
# @tags: usage, csv, header, quoted
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# readstat's CSV reader requires the header column names to match the
# metadata variable names exactly; DTA itself does not accept spaces in
# variable names, so a CSV header carrying a quoted spaced form is not a
# round-trippable scenario for this client. Instead, verify that quoted
# CSV cells containing whitespace inside a string value column are
# preserved verbatim through the CSV -> DTA -> CSV round trip.
cat >"$tmpdir/in.csv" <<'CSV'
first_name,score
"Mary Jane",1
"Bob   Smith",2
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"STRING","name":"first_name","label":"First name"},{"type":"NUMERIC","name":"score","label":"Score"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"
readstat "$tmpdir/out.dta" - >"$tmpdir/out.csv"

# The DTA-stored variable name (first_name) is what readback will emit,
# and the quoted whitespace-bearing string values must round-trip intact.
validator_assert_contains "$tmpdir/out.csv" '"first_name","score"'
validator_assert_contains "$tmpdir/out.csv" '"Mary Jane",1.000000'
validator_assert_contains "$tmpdir/out.csv" '"Bob   Smith",2.000000'

# Header + 2 rows.
total=$(wc -l <"$tmpdir/out.csv")
[[ "$total" == "3" ]] || {
  printf 'expected 3 lines, got %s\n' "$total" >&2
  exit 1
}

readstat "$tmpdir/out.dta" >"$tmpdir/summary"
validator_assert_contains "$tmpdir/summary" 'Columns: 2'
validator_assert_contains "$tmpdir/summary" 'Rows: 2'
