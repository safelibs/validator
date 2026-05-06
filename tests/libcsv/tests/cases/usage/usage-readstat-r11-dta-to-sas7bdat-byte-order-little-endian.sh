#!/usr/bin/env bash
# @testcase: usage-readstat-r11-dta-to-sas7bdat-byte-order-little-endian
# @title: readstat dta-to-sas7bdat summary reports little-endian byte order
# @description: Builds a SAS7BDAT from a CSV via DTA and verifies the readstat summary contains the "Byte order: little-endian" line, locking in that the SAS7BDAT writer on Ubuntu 24.04 emits little-endian byte order in its header (a field that the format records explicitly, unlike XPT which omits the line entirely).
# @timeout: 60
# @tags: usage, csv, sas7bdat, byte-order
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
id,name
1,alice
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"NUMERIC","name":"id","label":"ID"},{"type":"STRING","name":"name","label":"Name"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/mid.dta"
readstat "$tmpdir/mid.dta" "$tmpdir/out.sas7bdat"
readstat "$tmpdir/out.sas7bdat" >"$tmpdir/summary"

validator_assert_contains "$tmpdir/summary" 'Format: SAS data file (SAS7BDAT)'
grep -E '^Byte order: little-endian$' "$tmpdir/summary" >/dev/null || {
  printf 'SAS7BDAT summary did not pin byte order to little-endian\n' >&2
  cat "$tmpdir/summary" >&2
  exit 1
}
