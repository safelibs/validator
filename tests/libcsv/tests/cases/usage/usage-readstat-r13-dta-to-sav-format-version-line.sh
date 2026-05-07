#!/usr/bin/env bash
# @testcase: usage-readstat-r13-dta-to-sav-format-version-line
# @title: readstat DTA-to-SAV summary reports Format version: 2
# @description: Builds an SPSS SAV file from a CSV via DTA and verifies the readstat summary reports the precise "Format version: 2" line on the SAV path, locking in that readstat 1.1.9 on Ubuntu 24.04 emits SPSS layout version 2 (not 3) for newly written SAV files — distinguishing the SAV version line from the DTA 118 default.
# @timeout: 60
# @tags: usage, csv, sav, format-version
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
grep -E '^Format version: 2$' "$tmpdir/summary" >/dev/null || {
  printf 'SAV summary did not pin Format version to 2\n' >&2
  cat "$tmpdir/summary" >&2
  exit 1
}
