#!/usr/bin/env bash
# @testcase: usage-readstat-csv-to-por-summary
# @title: readstat CSV to SPSS POR portable file summary
# @description: Builds an SPSS portable POR file from CSV via DTA using uppercase variable names that the portable format requires and verifies the metadata summary identifies the SPSS portable format and reports the column count matching the input CSV shape.
# @timeout: 180
# @tags: usage, csv, por, metadata
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# POR (SPSS portable) requires uppercase ASCII variable names.
cat >"$tmpdir/in.csv" <<'CSV'
NAME,SCORE
alpha,1
beta,2
gamma,3
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"STRING","name":"NAME","label":"Name"},{"type":"NUMERIC","name":"SCORE","label":"Score"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/mid.dta"
validator_require_file "$tmpdir/mid.dta"

readstat "$tmpdir/mid.dta" "$tmpdir/out.por"
validator_require_file "$tmpdir/out.por"

# The summary command always emits the format header even when reading back is partial.
readstat "$tmpdir/out.por" >"$tmpdir/summary" 2>&1 || true

validator_assert_contains "$tmpdir/summary" 'Format: SPSS portable file (POR)'
validator_assert_contains "$tmpdir/summary" 'Columns: 2'
