#!/usr/bin/env bash
# @testcase: usage-readstat-r14-sas7bdat-summary-byte-order-line
# @title: readstat SAS7BDAT summary reports Byte order: little-endian by default
# @description: Builds a SAS7BDAT from a CSV via DTA and verifies the readstat summary contains the literal "Byte order: little-endian" line on the SAS7BDAT path, locking in little-endian as the default byte order emitted by the SAS7BDAT writer on Ubuntu 24.04 — distinguishing the SAS7BDAT byte-order line from the encoding line.
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
2,bob
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"NUMERIC","name":"id","label":"ID"},{"type":"STRING","name":"name","label":"Name"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/mid.dta"
readstat "$tmpdir/mid.dta" "$tmpdir/out.sas7bdat"
readstat "$tmpdir/out.sas7bdat" >"$tmpdir/summary"

validator_assert_contains "$tmpdir/summary" 'Format: SAS data file (SAS7BDAT)'
grep -E '^Byte order: little-endian$' "$tmpdir/summary" >/dev/null || {
  printf 'SAS7BDAT summary missing literal "Byte order: little-endian" line\n' >&2
  cat "$tmpdir/summary" >&2
  exit 1
}
