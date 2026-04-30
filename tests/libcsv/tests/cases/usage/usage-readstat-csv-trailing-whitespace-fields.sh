#!/usr/bin/env bash
# @testcase: usage-readstat-csv-trailing-whitespace-fields
# @title: readstat trailing whitespace inside string fields normalized to trimmed value
# @description: Builds a CSV whose quoted string fields carry trailing space characters after the actual content (for example "alpha   ", "beta    "), converts through DTA, and verifies that the readback emits the trimmed string content without the trailing spaces — distinguishing this case from the existing whitespace-only-field test which collapses all-whitespace to empty.
# @timeout: 180
# @tags: usage, csv, whitespace, trim
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Each name field has actual content followed by trailing spaces inside the quotes.
cat >"$tmpdir/in.csv" <<'CSV'
name,score
"alpha   ",1
"beta    ",2
"gamma  ",3
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"STRING","name":"name","label":"Name"},{"type":"NUMERIC","name":"score","label":"Score"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"
readstat "$tmpdir/out.dta" - >"$tmpdir/out.csv"

validator_assert_contains "$tmpdir/out.csv" '"name","score"'

# Trailing whitespace must have been trimmed: the readback should carry the
# bare content with no internal trailing spaces inside the quoted form.
validator_assert_contains "$tmpdir/out.csv" '"alpha",1.000000'
validator_assert_contains "$tmpdir/out.csv" '"beta",2.000000'
validator_assert_contains "$tmpdir/out.csv" '"gamma",3.000000'

# No quoted field in the readback should contain trailing spaces before the closing quote.
if grep -E '[A-Za-z][[:space:]]+"' "$tmpdir/out.csv" >/dev/null; then
  printf 'unexpected trailing whitespace inside quoted field\n' >&2
  cat "$tmpdir/out.csv" >&2
  exit 1
fi

# No empty-string fields either: trimming must not have collapsed the content entirely.
if grep -E '""' "$tmpdir/out.csv" >/dev/null; then
  printf 'string field unexpectedly collapsed to empty\n' >&2
  cat "$tmpdir/out.csv" >&2
  exit 1
fi

# Header + 3 rows.
total=$(wc -l <"$tmpdir/out.csv")
[[ "$total" == "4" ]] || {
  printf 'expected 4 lines, got %s\n' "$total" >&2
  exit 1
}

readstat "$tmpdir/out.dta" >"$tmpdir/summary"
validator_assert_contains "$tmpdir/summary" 'Columns: 2'
validator_assert_contains "$tmpdir/summary" 'Rows: 3'
