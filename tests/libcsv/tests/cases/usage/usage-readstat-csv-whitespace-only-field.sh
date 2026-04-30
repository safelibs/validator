#!/usr/bin/env bash
# @testcase: usage-readstat-csv-whitespace-only-field
# @title: readstat whitespace-only string field normalized to empty
# @description: Converts a CSV whose string field contains only space characters through DTA and verifies readstat normalizes whitespace-only fields to empty strings while preserving row count and other columns.
# @timeout: 180
# @tags: usage, csv, whitespace
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Quoted whitespace-only note fields. readstat trims these to empty strings;
# this test locks in that normalization without weakening the row/column checks.
cat >"$tmpdir/in.csv" <<'CSV'
name,note,score
alpha,"   ",1
beta,"  ",2
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"STRING","name":"name","label":"Name"},{"type":"STRING","name":"note","label":"Note"},{"type":"NUMERIC","name":"score","label":"Score"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"
readstat "$tmpdir/out.dta" - >"$tmpdir/out.csv"

validator_assert_contains "$tmpdir/out.csv" '"name","note","score"'
# Whitespace-only quoted fields are normalized to empty strings.
validator_assert_contains "$tmpdir/out.csv" '"alpha","",1.000000'
validator_assert_contains "$tmpdir/out.csv" '"beta","",2.000000'

# No leftover whitespace-only quoted note in the readback.
if grep -E '"[[:space:]]+",' "$tmpdir/out.csv" >/dev/null; then
  printf 'expected whitespace-only note to be normalized to empty\n' >&2
  cat "$tmpdir/out.csv" >&2
  exit 1
fi

readstat "$tmpdir/out.dta" >"$tmpdir/summary"
validator_assert_contains "$tmpdir/summary" 'Columns: 3'
validator_assert_contains "$tmpdir/summary" 'Rows: 2'
