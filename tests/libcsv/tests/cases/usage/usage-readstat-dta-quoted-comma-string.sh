#!/usr/bin/env bash
# @testcase: usage-readstat-dta-quoted-comma-string
# @title: readstat DTA quoted comma string
# @description: Converts a quoted CSV field containing a comma to DTA with readstat and verifies the embedded comma survives the round trip.
# @timeout: 180
# @tags: usage, csv, readstat
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-readstat-dta-quoted-comma-string"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
note
"alpha, beta"
CSV
cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"STRING","name":"note","label":"Note"}]}
JSON
readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"
readstat "$tmpdir/out.dta" - >"$tmpdir/out.csv"
validator_assert_contains "$tmpdir/out.csv" 'alpha, beta'
