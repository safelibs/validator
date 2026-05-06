#!/usr/bin/env bash
# @testcase: usage-readstat-r10-csv-sav-zsav-compression-distinguished
# @title: readstat distinguishes SAV row compression from ZSAV binary compression
# @description: Builds the same CSV through DTA into both an SPSS SAV file and an SPSS ZSAV file and verifies the metadata summaries report distinct compression algorithms (Compression: rows for SAV, Compression: binary for ZSAV), confirming the two SPSS variants are not collapsed onto a single compression mode in the readstat CLI output.
# @timeout: 180
# @tags: usage, csv, sav, zsav, compression
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
name,score
alpha,1
beta,2
gamma,3
delta,4
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"STRING","name":"name","label":"Name"},{"type":"NUMERIC","name":"score","label":"Score"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/mid.dta"
readstat "$tmpdir/mid.dta" "$tmpdir/out.sav"
readstat "$tmpdir/mid.dta" "$tmpdir/out.zsav"

readstat "$tmpdir/out.sav" >"$tmpdir/sav.summary"
readstat "$tmpdir/out.zsav" >"$tmpdir/zsav.summary"

# SAV uses row compression by default.
validator_assert_contains "$tmpdir/sav.summary" 'Compression: rows'
validator_assert_contains "$tmpdir/sav.summary" 'SPSS binary file (SAV)'

# ZSAV uses binary (zlib) compression.
validator_assert_contains "$tmpdir/zsav.summary" 'Compression: binary'
validator_assert_contains "$tmpdir/zsav.summary" 'SPSS compressed binary file (ZSAV)'

# Negative checks: the modes must not be swapped.
if grep -E '^Compression: binary$' "$tmpdir/sav.summary" >/dev/null; then
  printf 'SAV summary unexpectedly reports binary compression\n' >&2
  cat "$tmpdir/sav.summary" >&2
  exit 1
fi
if grep -E '^Compression: rows$' "$tmpdir/zsav.summary" >/dev/null; then
  printf 'ZSAV summary unexpectedly reports rows compression\n' >&2
  cat "$tmpdir/zsav.summary" >&2
  exit 1
fi
