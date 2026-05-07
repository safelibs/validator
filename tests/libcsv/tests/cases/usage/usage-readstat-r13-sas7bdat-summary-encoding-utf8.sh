#!/usr/bin/env bash
# @testcase: usage-readstat-r13-sas7bdat-summary-encoding-utf8
# @title: readstat SAS7BDAT summary reports Text encoding UTF-8 by default
# @description: Builds a SAS7BDAT from a CSV via DTA and verifies the readstat summary contains the literal "Text encoding: UTF-8" line on the SAS7BDAT path, distinguishing the SAS data file encoding default from the (well-known) DTA default and from the XPT path which omits the encoding line.
# @timeout: 60
# @tags: usage, csv, sas7bdat, encoding
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
grep -E '^Text encoding: UTF-8$' "$tmpdir/summary" >/dev/null || {
  printf 'SAS7BDAT summary missing literal "Text encoding: UTF-8" line\n' >&2
  cat "$tmpdir/summary" >&2
  exit 1
}
