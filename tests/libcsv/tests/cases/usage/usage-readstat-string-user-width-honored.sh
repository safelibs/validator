#!/usr/bin/env bash
# @testcase: usage-readstat-string-user-width-honored
# @title: readstat honors user_width metadata for string columns
# @description: Builds a DTA from CSV with a STRING column carrying a 20-character "user_width" hint in metadata and a 20-character value, then verifies the round-trip back to CSV keeps the full unmodified string and the DTA summary still reports two rows and two columns.
# @timeout: 120
# @tags: usage, csv, metadata, width
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
name,score
abcdefghijabcdefghij,42
xy,7
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"STRING","name":"name","label":"Name","user_width":20},{"type":"NUMERIC","name":"score","label":"Score"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"

readstat "$tmpdir/out.dta" >"$tmpdir/summary"
validator_assert_contains "$tmpdir/summary" 'Columns: 2'
validator_assert_contains "$tmpdir/summary" 'Rows: 2'

readstat "$tmpdir/out.dta" - >"$tmpdir/back.csv"

validator_assert_contains "$tmpdir/back.csv" '"name","score"'
validator_assert_contains "$tmpdir/back.csv" '"abcdefghijabcdefghij",42.000000'
validator_assert_contains "$tmpdir/back.csv" '"xy",7.000000'

# The 20-character value must come back intact; truncation would have shortened it.
if grep -F '"abcdefghijabcdefghij"' "$tmpdir/back.csv" | head -n1 >/dev/null; then
  long_line=$(grep -F '"abcdefghijabcdefghij"' "$tmpdir/back.csv" | head -n1)
  if [[ ${#long_line} -lt 30 ]]; then
    printf 'long string row appears truncated: %s\n' "$long_line" >&2
    exit 1
  fi
fi
