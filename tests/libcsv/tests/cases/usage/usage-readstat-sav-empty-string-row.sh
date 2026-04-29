#!/usr/bin/env bash
# @testcase: usage-readstat-sav-empty-string-row
# @title: readstat SAV empty string row
# @description: Converts a CSV row containing an empty quoted string to SAV with readstat and verifies the summary still reports a single column.
# @timeout: 180
# @tags: usage, csv, readstat
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-readstat-sav-empty-string-row"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'note\n""\n' >"$tmpdir/in.csv"
cat >"$tmpdir/meta.json" <<'JSON'
{"type":"SPSS","variables":[{"type":"STRING","name":"note","label":"Note"}]}
JSON
readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.sav"
readstat "$tmpdir/out.sav" >"$tmpdir/summary"
validator_assert_contains "$tmpdir/summary" 'Columns: 1'
