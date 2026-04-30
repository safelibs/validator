#!/usr/bin/env bash
# @testcase: usage-readstat-sas7bdat-summary-format
# @title: readstat SAS7BDAT summary metadata
# @description: Builds a SAS7BDAT file from CSV via DTA and verifies the metadata summary identifies the SAS data format and reports the dataset shape.
# @timeout: 180
# @tags: usage, csv, sas7bdat, metadata
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

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/mid.dta"
readstat "$tmpdir/mid.dta" "$tmpdir/out.sas7bdat"
readstat "$tmpdir/out.sas7bdat" >"$tmpdir/summary"

validator_assert_contains "$tmpdir/summary" 'SAS data file (SAS7BDAT)'
validator_assert_contains "$tmpdir/summary" 'Table name: DATASET'
validator_assert_contains "$tmpdir/summary" 'Text encoding: UTF-8'
validator_assert_contains "$tmpdir/summary" 'Byte order: little-endian'
validator_assert_contains "$tmpdir/summary" 'Columns: 2'
validator_assert_contains "$tmpdir/summary" 'Rows: 3'
