#!/usr/bin/env bash
# @testcase: usage-readstat-dta-sav-dta-numeric-type
# @title: readstat numeric column survives DTA SAV DTA hop
# @description: Converts a CSV with one string column and one numeric column to DTA, hops through SAV, then back to a second DTA, and verifies the numeric column still emits six-decimal numeric values (rather than quoted strings) on the final readback, confirming type information survives the cross-format hop.
# @timeout: 240
# @tags: usage, csv, types, multistep
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
name,score
alpha,5
beta,15
gamma,25
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"STRING","name":"name","label":"Name"},{"type":"NUMERIC","name":"score","label":"Score"}]}
JSON

# CSV -> DTA -> SAV -> DTA.
readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/step1.dta"
readstat "$tmpdir/step1.dta" "$tmpdir/step2.sav"
readstat "$tmpdir/step2.sav" "$tmpdir/step3.dta"
validator_require_file "$tmpdir/step3.dta"

readstat "$tmpdir/step3.dta" - >"$tmpdir/out.csv"

validator_assert_contains "$tmpdir/out.csv" '"name","score"'
validator_assert_contains "$tmpdir/out.csv" '"alpha",5.000000'
validator_assert_contains "$tmpdir/out.csv" '"beta",15.000000'
validator_assert_contains "$tmpdir/out.csv" '"gamma",25.000000'

# The numeric values must NOT come out quoted (e.g., "5.000000") which would
# indicate the type was downgraded to string somewhere in the hop.
if grep -E '"alpha","[0-9]' "$tmpdir/out.csv" >/dev/null; then
  printf 'numeric column was quoted (downgraded to string)\n' >&2
  cat "$tmpdir/out.csv" >&2
  exit 1
fi

# Each hop must report Columns: 2 / Rows: 3 with consistent shape.
for f in "$tmpdir/step1.dta" "$tmpdir/step2.sav" "$tmpdir/step3.dta"; do
  readstat "$f" >"$tmpdir/summary"
  validator_assert_contains "$tmpdir/summary" 'Columns: 2'
  validator_assert_contains "$tmpdir/summary" 'Rows: 3'
done
