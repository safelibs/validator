#!/usr/bin/env bash
# @testcase: usage-readstat-r16-dta-stdout-dash-csv-shape
# @title: readstat dta-to-stdout dash target emits a CSV with quoted header
# @description: Converts a small CSV to .dta and back to stdout CSV via the "-" target, asserting the produced CSV's first line is a comma-separated quoted header listing both column names — locking in the dash-target stdout CSV output shape.
# @timeout: 60
# @tags: usage, csv, dta, stdout, dash
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
alpha,beta
1,2
3,4
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"NUMERIC","name":"alpha","label":"A"},{"type":"NUMERIC","name":"beta","label":"B"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"
readstat "$tmpdir/out.dta" - >"$tmpdir/out.csv"

head -1 "$tmpdir/out.csv" >"$tmpdir/header"
grep -Fq '"alpha"' "$tmpdir/header"
grep -Fq '"beta"' "$tmpdir/header"
grep -Fq ',' "$tmpdir/header"
