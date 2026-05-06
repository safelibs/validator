#!/usr/bin/env bash
# @testcase: usage-readstat-r11-dta-to-sas7bdat-format-version-9
# @title: readstat dta-to-sas7bdat summary pins Format version to 9
# @description: Builds a SAS7BDAT from a CSV via DTA and verifies the readstat summary reports the SAS data file format with the specific "Format version: 9" line that locks in SAS7BDAT v9 as the format version emitted by the readstat SAS7BDAT writer on Ubuntu 24.04.
# @timeout: 60
# @tags: usage, csv, sas7bdat, format-version
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
grep -E '^Format version: 9$' "$tmpdir/summary" >/dev/null || {
  printf 'SAS7BDAT summary did not pin Format version to 9\n' >&2
  cat "$tmpdir/summary" >&2
  exit 1
}
