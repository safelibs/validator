#!/usr/bin/env bash
# @testcase: usage-readstat-csv-constant-first-column
# @title: readstat CSV with constant first column preserves repeated value across all rows
# @description: Builds a two-column CSV where the first column carries the same string value on every data row (a degenerate constant column) and the second column varies, converts through DTA, and verifies every readback row repeats the constant verbatim so no row collapses or deduplicates the value.
# @timeout: 180
# @tags: usage, csv, constant, mixed
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
group,score
team,11
team,22
team,33
team,44
team,55
team,66
team,77
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"STRING","name":"group","label":"Group"},{"type":"NUMERIC","name":"score","label":"Score"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"
readstat "$tmpdir/out.dta" - >"$tmpdir/out.csv"

# Header preserved verbatim.
validator_assert_contains "$tmpdir/out.csv" '"group","score"'

# Every data row must repeat the constant "team" with its paired score.
expected_rows=(
  '"team",11.000000'
  '"team",22.000000'
  '"team",33.000000'
  '"team",44.000000'
  '"team",55.000000'
  '"team",66.000000'
  '"team",77.000000'
)
for row in "${expected_rows[@]}"; do
  validator_assert_contains "$tmpdir/out.csv" "$row"
done

# The constant must appear on exactly 7 lines (no collapse, no extra duplication).
team_count=$(grep -c '^"team",' "$tmpdir/out.csv")
[[ "$team_count" == "7" ]] || {
  printf 'expected constant to appear on 7 lines, got %s\n' "$team_count" >&2
  cat "$tmpdir/out.csv" >&2
  exit 1
}

# Header + 7 data rows.
total=$(wc -l <"$tmpdir/out.csv")
[[ "$total" == "8" ]] || {
  printf 'expected 8 lines, got %s\n' "$total" >&2
  exit 1
}

readstat "$tmpdir/out.dta" >"$tmpdir/summary"
validator_assert_contains "$tmpdir/summary" 'Columns: 2'
validator_assert_contains "$tmpdir/summary" 'Rows: 7'
