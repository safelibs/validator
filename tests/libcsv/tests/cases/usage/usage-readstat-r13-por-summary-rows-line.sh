#!/usr/bin/env bash
# @testcase: usage-readstat-r13-por-summary-rows-line
# @title: readstat POR summary reports Rows: -1 because the portable header lacks a row count
# @description: Builds an SPSS POR file from a CSV via DTA using uppercase variable names that the portable format requires, and verifies the readstat summary reports the literal "Rows: -1" line, locking in that POR shares the XPORT-style "row count not available from header" behaviour and distinguishing it from the DTA path which reports the precise row count.
# @timeout: 120
# @tags: usage, csv, por, summary
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
NAME,SCORE
alpha,1
beta,2
gamma,3
delta,4
epsilon,5
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"STRING","name":"NAME","label":"Name"},{"type":"NUMERIC","name":"SCORE","label":"S"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/mid.dta"
readstat "$tmpdir/mid.dta" "$tmpdir/out.por"
readstat "$tmpdir/out.por" >"$tmpdir/summary" 2>&1 || true

validator_assert_contains "$tmpdir/summary" 'Format: SPSS portable file (POR)'
grep -E '^Rows: -1$' "$tmpdir/summary" >/dev/null || {
  printf 'POR summary did not pin Rows to -1\n' >&2
  cat "$tmpdir/summary" >&2
  exit 1
}
# Sanity: the same POR carries 2 columns (matching the input CSV).
validator_assert_contains "$tmpdir/summary" 'Columns: 2'
