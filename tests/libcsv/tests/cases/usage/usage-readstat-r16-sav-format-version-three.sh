#!/usr/bin/env bash
# @testcase: usage-readstat-r16-sav-format-version-three
# @title: readstat-built SAV file reports format-version 3 in its summary
# @description: Builds a small SAV via readstat from CSV+meta and asserts the summary contains "Format version: 3" — locking in the default SAV writer's version number on Ubuntu 24.04 readstat 1.1.9, independent of compression mode.
# @timeout: 60
# @tags: usage, csv, sav, format-version
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
id,score
1,10
2,20
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"SPSS","variables":[{"type":"NUMERIC","name":"id","label":"ID"},{"type":"NUMERIC","name":"score","label":"Score"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.sav"
readstat "$tmpdir/out.sav" >"$tmpdir/summary"

validator_assert_contains "$tmpdir/summary" 'Format version: 3'
