#!/usr/bin/env bash
# @testcase: usage-readstat-csv-dta-sav-dta-5row-exact
# @title: readstat CSV through DTA SAV DTA preserves five rows exactly
# @description: Round-trips a five-row CSV through DTA then SAV then back to DTA, dumps the final DTA as CSV, and verifies every one of the five data rows reappears at its original position with both string and numeric values intact.
# @timeout: 240
# @tags: usage, csv, multistep
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
name,score
row1,11
row2,22
row3,33
row4,44
row5,55
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"STRING","name":"name","label":"Name"},{"type":"NUMERIC","name":"score","label":"Score"}]}
JSON

# CSV -> DTA.
readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/step1.dta"
validator_require_file "$tmpdir/step1.dta"

# DTA -> SAV.
readstat "$tmpdir/step1.dta" "$tmpdir/step2.sav"
validator_require_file "$tmpdir/step2.sav"

# SAV -> DTA.
readstat "$tmpdir/step2.sav" "$tmpdir/step3.dta"
validator_require_file "$tmpdir/step3.dta"

# Each hop must agree on shape.
for f in "$tmpdir/step1.dta" "$tmpdir/step2.sav" "$tmpdir/step3.dta"; do
  readstat "$f" >"$tmpdir/summary"
  validator_assert_contains "$tmpdir/summary" 'Columns: 2'
  validator_assert_contains "$tmpdir/summary" 'Rows: 5'
done

# Final readback must carry every row at its original line position.
readstat "$tmpdir/step3.dta" - >"$tmpdir/out.csv"

declare -A expected=(
  [2]='"row1",11.000000'
  [3]='"row2",22.000000'
  [4]='"row3",33.000000'
  [5]='"row4",44.000000'
  [6]='"row5",55.000000'
)
for ln in 2 3 4 5 6; do
  actual=$(sed -n "${ln}p" "$tmpdir/out.csv")
  [[ "$actual" == "${expected[$ln]}" ]] || {
    printf 'line %s mismatch: expected %s, got %s\n' "$ln" "${expected[$ln]}" "$actual" >&2
    cat "$tmpdir/out.csv" >&2
    exit 1
  }
done

# Header + 5 data rows.
total=$(wc -l <"$tmpdir/out.csv")
[[ "$total" == "6" ]] || {
  printf 'expected 6 lines, got %s\n' "$total" >&2
  exit 1
}
