#!/usr/bin/env bash
# @testcase: usage-readstat-zsav-compression-summary
# @title: readstat ZSAV compression summary
# @description: Builds a ZSAV file from CSV via DTA and verifies the metadata summary reports binary compression and matching row and column counts.
# @timeout: 180
# @tags: usage, csv, zsav, metadata
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
name,score,note
alpha,10,first
beta,20,second
gamma,30,third
delta,40,fourth
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"STRING","name":"name","label":"Name"},{"type":"NUMERIC","name":"score","label":"Score"},{"type":"STRING","name":"note","label":"Note"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/mid.dta"
readstat "$tmpdir/mid.dta" "$tmpdir/out.zsav"
readstat "$tmpdir/out.zsav" >"$tmpdir/summary"

validator_assert_contains "$tmpdir/summary" 'SPSS compressed binary file (ZSAV)'
validator_assert_contains "$tmpdir/summary" 'Compression: binary'
validator_assert_contains "$tmpdir/summary" 'Text encoding: UTF-8'
validator_assert_contains "$tmpdir/summary" 'Byte order: little-endian'
validator_assert_contains "$tmpdir/summary" 'Columns: 3'
validator_assert_contains "$tmpdir/summary" 'Rows: 4'
