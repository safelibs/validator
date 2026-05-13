#!/usr/bin/env bash
# @testcase: usage-readstat-r16-zsav-format-version-three
# @title: readstat-built ZSAV file reports format-version 3 in its summary
# @description: Builds a ZSAV via the CSV->DTA->ZSAV chain and asserts the summary contains both "Format version: 3" and the "ZSAV" format label — locking in the binary-compressed SPSS writer's metadata shape on Ubuntu 24.04.
# @timeout: 60
# @tags: usage, csv, zsav, format-version
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
a,b
1,2
3,4
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"NUMERIC","name":"a","label":"A"},{"type":"NUMERIC","name":"b","label":"B"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/mid.dta"
readstat "$tmpdir/mid.dta" "$tmpdir/out.zsav"
readstat "$tmpdir/out.zsav" >"$tmpdir/summary"

validator_assert_contains "$tmpdir/summary" 'Format version: 3'
validator_assert_contains "$tmpdir/summary" 'ZSAV'
