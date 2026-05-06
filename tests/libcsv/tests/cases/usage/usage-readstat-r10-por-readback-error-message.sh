#!/usr/bin/env bash
# @testcase: usage-readstat-r10-por-readback-error-message
# @title: readstat surfaces an explicit error reading SPSS portable POR back to CSV
# @description: Builds an SPSS portable POR file from a CSV via DTA and then attempts to convert that POR file back to CSV, verifying readstat does not silently produce empty output but instead emits an "Error processing" diagnostic naming the POR path with an "Invalid file, or file has unsupported features" reason and refuses to create the destination CSV file.
# @timeout: 120
# @tags: usage, csv, por, negative
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# POR (SPSS portable) requires uppercase ASCII variable names.
cat >"$tmpdir/in.csv" <<'CSV'
NAME,SCORE
ALPHA,1
BETA,2
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"STRING","name":"NAME","label":"Name"},{"type":"NUMERIC","name":"SCORE","label":"Score"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/mid.dta"
readstat "$tmpdir/mid.dta" "$tmpdir/out.por"
validator_require_file "$tmpdir/out.por"

# Attempt to read back: this must surface an explicit error.
readstat "$tmpdir/out.por" "$tmpdir/back.csv" \
  >"$tmpdir/stdout" 2>"$tmpdir/stderr" || true
cat "$tmpdir/stdout" "$tmpdir/stderr" >"$tmpdir/all"

validator_assert_contains "$tmpdir/all" 'Error processing'
validator_assert_contains "$tmpdir/all" 'out.por'
validator_assert_contains "$tmpdir/all" 'Invalid file, or file has unsupported features'

# The destination CSV must NOT have been written.
if [[ -e "$tmpdir/back.csv" ]]; then
  printf 'unexpected back.csv created from POR readback\n' >&2
  ls -la "$tmpdir/back.csv" >&2
  exit 1
fi
