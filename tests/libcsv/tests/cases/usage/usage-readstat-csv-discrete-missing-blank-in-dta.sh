#!/usr/bin/env bash
# @testcase: usage-readstat-csv-discrete-missing-blank-in-dta
# @title: readstat renders DISCRETE missing values as blanks when DTA is read back
# @description: Builds CSV plus JSON metadata that declares a DISCRETE missing-value sentinel of 99 on a numeric column, converts to DTA, reads the DTA back to CSV, and verifies the row whose score equals 99 emits an empty cell ("beta,") while non-sentinel rows preserve their numeric value (alpha,42 and gamma,7 stay populated). Locks in the libreadstat behavior of suppressing user-declared missing sentinels at DTA readback time.
# @timeout: 120
# @tags: usage, csv, dta, missing, metadata
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
name,score
alpha,42
beta,99
gamma,7
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"STRING","name":"name","label":"Name"},{"type":"NUMERIC","name":"score","label":"Score","missing":{"type":"DISCRETE","values":[99]}}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"
validator_require_file "$tmpdir/out.dta"

readstat "$tmpdir/out.dta" - >"$tmpdir/out.csv"
validator_assert_contains "$tmpdir/out.csv" '"name","score"'
validator_assert_contains "$tmpdir/out.csv" '"alpha",42.000000'
validator_assert_contains "$tmpdir/out.csv" '"gamma",7.000000'

# beta's score must come back blank (the sentinel was suppressed).
if ! grep -E '^"beta",[[:space:]]*$' "$tmpdir/out.csv" >/dev/null; then
  printf 'expected beta row to render with blank score in DTA readback\n' >&2
  cat "$tmpdir/out.csv" >&2
  exit 1
fi

# It must NOT come back as 99 — that would mean the missing tag was lost.
if grep -F '"beta",99' "$tmpdir/out.csv" >/dev/null; then
  printf 'beta still renders as 99; missing-value tag was not honored\n' >&2
  cat "$tmpdir/out.csv" >&2
  exit 1
fi

readstat "$tmpdir/out.dta" >"$tmpdir/summary"
validator_assert_contains "$tmpdir/summary" 'Columns: 2'
validator_assert_contains "$tmpdir/summary" 'Rows: 3'
