#!/usr/bin/env bash
# @testcase: usage-readstat-sav-small-decimal-batch11
# @title: readstat SAV small decimal
# @description: Roundtrips a small decimal through readstat SAV conversion.
# @timeout: 180
# @tags: usage, csv, readstat
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-readstat-sav-small-decimal-batch11"
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

printf 'note,value\nsmall,0.125\n' >"$tmpdir/in.csv"
write_meta SPSS
readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.sav"
readstat "$tmpdir/out.sav" - >"$tmpdir/out.csv"
validator_assert_contains "$tmpdir/out.csv" '0.125000'
