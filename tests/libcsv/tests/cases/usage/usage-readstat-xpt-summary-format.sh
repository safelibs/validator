#!/usr/bin/env bash
# @testcase: usage-readstat-xpt-summary-format
# @title: readstat XPT summary metadata
# @description: Generates an XPT file from CSV via DTA and verifies the metadata summary identifies the SAS transport format and column count.
# @timeout: 180
# @tags: usage, csv, xpt, metadata
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
name,score,note
alpha,1,first
beta,2,second
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"STRING","name":"name","label":"Name"},{"type":"NUMERIC","name":"score","label":"Score"},{"type":"STRING","name":"note","label":"Note"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/mid.dta"
readstat "$tmpdir/mid.dta" "$tmpdir/out.xpt"
readstat "$tmpdir/out.xpt" >"$tmpdir/summary"

validator_assert_contains "$tmpdir/summary" 'SAS transport file (XPORT)'
validator_assert_contains "$tmpdir/summary" 'Columns: 3'
validator_assert_contains "$tmpdir/summary" 'Format version: 8'
validator_assert_contains "$tmpdir/summary" 'Table name: DATASET'
