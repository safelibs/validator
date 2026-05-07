#!/usr/bin/env bash
# @testcase: usage-readstat-r15-zsav-summary-columns-line
# @title: readstat ZSAV summary reports Columns: 2 like SAV does
# @description: Builds a 2-column ZSAV from a CSV via DTA and verifies the readstat summary contains the literal "Columns: 2" line — locking in that the ZSAV (binary-compressed SPSS) writer reports column count identically to plain SAV on Ubuntu 24.04 readstat 1.1.9, even though the format-version differs (3 for ZSAV vs 2 for SAV).
# @timeout: 60
# @tags: usage, csv, zsav, columns
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
readstat "$tmpdir/mid.dta" "$tmpdir/out.zsav"
readstat "$tmpdir/out.zsav" >"$tmpdir/summary"

grep -E '^Columns: 2$' "$tmpdir/summary" >/dev/null || {
  printf 'ZSAV summary did not pin Columns to 2\n' >&2
  cat "$tmpdir/summary" >&2
  exit 1
}
validator_assert_contains "$tmpdir/summary" 'Format: SPSS compressed binary file (ZSAV)'
