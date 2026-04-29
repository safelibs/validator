#!/usr/bin/env bash
# @testcase: usage-readstat-dta-underscore-header-batch11
# @title: readstat DTA underscore header
# @description: Writes a DTA file from a CSV column with an underscore header.
# @timeout: 180
# @tags: usage, csv, readstat
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-readstat-dta-underscore-header-batch11"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

write_meta() {
  local type=$1
  cat >"$tmpdir/meta.json" <<JSON
{"type":"$type","variables":[{"type":"STRING","name":"note","label":"Note"},{"type":"NUMERIC","name":"value","label":"Value"}]}
JSON
}

write_string_meta() {
  local type=$1
  cat >"$tmpdir/meta.json" <<JSON
{"type":"$type","variables":[{"type":"STRING","name":"note","label":"Note"}]}
JSON
}

printf 'note_value\nalpha\n' >"$tmpdir/in.csv"
cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"STRING","name":"note_value","label":"Note Value"}]}
JSON
readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"
readstat "$tmpdir/out.dta" >"$tmpdir/summary"
validator_assert_contains "$tmpdir/summary" 'Columns: 1'
