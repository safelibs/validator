#!/usr/bin/env bash
# @testcase: usage-readstat-csv-sas7bdat-to-xpt-cross-format
# @title: readstat converts CSV-built SAS7BDAT into an XPT transport file
# @description: Pipelines CSV plus JSON metadata into a DTA, then DTA into a SAS7BDAT, then SAS7BDAT into an XPT transport file, and finally reads the XPT back to CSV. Verifies the XPT summary identifies the transport format and the readback CSV preserves the three rows produced by the SAS7BDAT -> XPT writer chain (a path that exercises libreadstat's SAS reader and the XPT writer).
# @timeout: 240
# @tags: usage, csv, sas7bdat, xpt, cross-format
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
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"STRING","name":"name","label":"Name"},{"type":"NUMERIC","name":"score","label":"Score"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/mid.dta"
readstat "$tmpdir/mid.dta" "$tmpdir/mid.sas7bdat"
validator_require_file "$tmpdir/mid.sas7bdat"

# SAS7BDAT -> XPT directly: no JSON metadata is reused.
readstat "$tmpdir/mid.sas7bdat" "$tmpdir/out.xpt"
validator_require_file "$tmpdir/out.xpt"

readstat "$tmpdir/out.xpt" >"$tmpdir/summary"
validator_assert_contains "$tmpdir/summary" 'Format: SAS transport file (XPORT)'
validator_assert_contains "$tmpdir/summary" 'Columns: 2'

readstat "$tmpdir/out.xpt" - >"$tmpdir/out.csv"
validator_assert_contains "$tmpdir/out.csv" '"name","score"'
validator_assert_contains "$tmpdir/out.csv" '"alpha",1.000000'
validator_assert_contains "$tmpdir/out.csv" '"beta",2.000000'
validator_assert_contains "$tmpdir/out.csv" '"gamma",3.000000'

# XPT must contain three data rows in addition to the header line.
data_rows=$(grep -c '^"' "$tmpdir/out.csv")
if [[ "$data_rows" -ne 4 ]]; then
  printf 'expected 4 quoted lines (header + 3 rows), got %s\n' "$data_rows" >&2
  cat "$tmpdir/out.csv" >&2
  exit 1
fi
