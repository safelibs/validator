#!/usr/bin/env bash
# @testcase: usage-readstat-r14-dta-to-zsav-roundtrip-row-count
# @title: readstat DTA-to-ZSAV preserves the precise row count across the binary-compressed write
# @description: Round-trips a 5-row CSV through DTA, then writes the DTA out as a ZSAV (binary-compressed SPSS), and verifies the ZSAV summary reports exactly the same row count as the source — confirming the binary-compression path of the ZSAV writer does not lose or duplicate rows on Ubuntu 24.04 readstat 1.1.9.
# @timeout: 120
# @tags: usage, csv, zsav, roundtrip
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
id,score
1,10
2,20
3,30
4,40
5,50
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"NUMERIC","name":"id","label":"ID"},{"type":"NUMERIC","name":"score","label":"Score"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/mid.dta"
readstat "$tmpdir/mid.dta" "$tmpdir/out.zsav"
readstat "$tmpdir/out.zsav" >"$tmpdir/summary"

validator_assert_contains "$tmpdir/summary" 'Format: SPSS compressed binary file (ZSAV)'
grep -E '^Rows: 5$' "$tmpdir/summary" >/dev/null || {
  printf 'ZSAV summary did not pin Rows to 5\n' >&2
  cat "$tmpdir/summary" >&2
  exit 1
}
validator_assert_contains "$tmpdir/summary" 'Columns: 2'
