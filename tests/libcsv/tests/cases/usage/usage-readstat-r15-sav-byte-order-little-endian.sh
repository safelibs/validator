#!/usr/bin/env bash
# @testcase: usage-readstat-r15-sav-byte-order-little-endian
# @title: readstat SAV summary reports Byte order: little-endian by default
# @description: Builds a SAV from a CSV via DTA and verifies the readstat summary contains the literal "Byte order: little-endian" line on the SAV path — locking in little-endian as the default byte order emitted by the readstat SAV writer on Ubuntu 24.04 readstat 1.1.9. Distinct from the DTA and SAS7BDAT byte-order tests already in r13/r14.
# @timeout: 60
# @tags: usage, csv, sav, byte-order
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
grep -E '^Byte order: little-endian$' "$tmpdir/summary" >/dev/null || {
  printf 'SAV summary missing literal "Byte order: little-endian" line\n' >&2
  cat "$tmpdir/summary" >&2
  exit 1
}
