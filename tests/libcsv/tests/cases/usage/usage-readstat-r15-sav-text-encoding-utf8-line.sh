#!/usr/bin/env bash
# @testcase: usage-readstat-r15-sav-text-encoding-utf8-line
# @title: readstat SAV summary reports Text encoding: UTF-8 by default
# @description: Builds a SAV from a CSV via DTA and verifies the readstat summary contains the literal "Text encoding: UTF-8" line on the SAV path — locking in UTF-8 as the default text encoding emitted by the readstat SAV writer on Ubuntu 24.04 readstat 1.1.9. Distinct from the SAS7BDAT encoding-utf8 test in r13.
# @timeout: 60
# @tags: usage, csv, sav, encoding
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
id,name
1,alice
2,bob
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"NUMERIC","name":"id","label":"ID"},{"type":"STRING","name":"name","label":"Name"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/mid.dta"
readstat "$tmpdir/mid.dta" "$tmpdir/out.sav"
readstat "$tmpdir/out.sav" >"$tmpdir/summary"

validator_assert_contains "$tmpdir/summary" 'Format: SPSS binary file (SAV)'
grep -E '^Text encoding: UTF-8$' "$tmpdir/summary" >/dev/null || {
  printf 'SAV summary missing literal "Text encoding: UTF-8" line\n' >&2
  cat "$tmpdir/summary" >&2
  exit 1
}
