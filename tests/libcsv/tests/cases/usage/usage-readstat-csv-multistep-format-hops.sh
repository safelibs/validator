#!/usr/bin/env bash
# @testcase: usage-readstat-csv-multistep-format-hops
# @title: readstat CSV through DTA SAV and back to CSV
# @description: Round-trips a CSV through DTA, then through SAV, then back to CSV via DTA, verifying string and numeric values survive every hop.
# @timeout: 240
# @tags: usage, csv, multistep
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
name,score
alpha,11
beta,22
gamma,33
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"STRING","name":"name","label":"Name"},{"type":"NUMERIC","name":"score","label":"Score"}]}
JSON

# Step 1: CSV -> DTA.
readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/step1.dta"
validator_require_file "$tmpdir/step1.dta"

# Step 2: DTA -> SAV.
readstat "$tmpdir/step1.dta" "$tmpdir/step2.sav"
validator_require_file "$tmpdir/step2.sav"

# Step 3: SAV -> DTA.
readstat "$tmpdir/step2.sav" "$tmpdir/step3.dta"
validator_require_file "$tmpdir/step3.dta"

# Step 4: DTA -> CSV (final readback).
readstat "$tmpdir/step3.dta" - >"$tmpdir/out.csv"

validator_assert_contains "$tmpdir/out.csv" '"name","score"'
validator_assert_contains "$tmpdir/out.csv" '"alpha",11.000000'
validator_assert_contains "$tmpdir/out.csv" '"beta",22.000000'
validator_assert_contains "$tmpdir/out.csv" '"gamma",33.000000'

# Summary at every hop must agree on shape.
for f in "$tmpdir/step1.dta" "$tmpdir/step2.sav" "$tmpdir/step3.dta"; do
  readstat "$f" >"$tmpdir/summary"
  validator_assert_contains "$tmpdir/summary" 'Columns: 2'
  validator_assert_contains "$tmpdir/summary" 'Rows: 3'
done
