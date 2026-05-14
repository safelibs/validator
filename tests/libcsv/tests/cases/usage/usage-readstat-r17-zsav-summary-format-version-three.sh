#!/usr/bin/env bash
# @testcase: usage-readstat-r17-zsav-summary-format-version-three
# @title: readstat ZSAV summary still reports Format version 3 for a three-column input
# @description: Builds a ZSAV from a three-column CSV via the DTA intermediate path and asserts the summary contains "Format version: 3" plus the ZSAV format label — locking in noble's compressed-SPSS writer for a wider input than the r16 two-column variant.
# @timeout: 60
# @tags: usage, csv, zsav, version
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
a,b,c
1,2,3
4,5,6
7,8,9
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"NUMERIC","name":"a","label":"A"},{"type":"NUMERIC","name":"b","label":"B"},{"type":"NUMERIC","name":"c","label":"C"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/mid.dta"
readstat "$tmpdir/mid.dta" "$tmpdir/out.zsav"
readstat "$tmpdir/out.zsav" >"$tmpdir/summary"

validator_assert_contains "$tmpdir/summary" 'Format version: 3'
validator_assert_contains "$tmpdir/summary" 'ZSAV'
