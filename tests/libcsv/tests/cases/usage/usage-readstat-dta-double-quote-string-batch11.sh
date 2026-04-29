#!/usr/bin/env bash
# @testcase: usage-readstat-dta-double-quote-string-batch11
# @title: readstat DTA double quote string
# @description: Roundtrips an escaped double quote string through readstat DTA conversion.
# @timeout: 180
# @tags: usage, csv, readstat
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-readstat-dta-double-quote-string-batch11"
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

printf 'note\n"alpha ""quoted"""\n' >"$tmpdir/in.csv"
write_string_meta Stata
readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"
readstat "$tmpdir/out.dta" - >"$tmpdir/out.csv"
validator_assert_contains "$tmpdir/out.csv" '"alpha ""quoted"""'
