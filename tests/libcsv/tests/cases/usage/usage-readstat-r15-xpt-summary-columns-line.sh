#!/usr/bin/env bash
# @testcase: usage-readstat-r15-xpt-summary-columns-line
# @title: readstat XPT summary reports Columns: 2 for a 2-column input
# @description: Builds a 2-column XPT from a CSV via DTA and verifies the readstat summary contains the literal "Columns: 2" line — locking in that the SAS XPORT writer's metadata path reports column count as a top-level summary field on Ubuntu 24.04 readstat 1.1.9, complementary to the existing XPT format-version-8 and table-name tests.
# @timeout: 60
# @tags: usage, csv, xpt, columns
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
readstat "$tmpdir/mid.dta" "$tmpdir/out.xpt"
readstat "$tmpdir/out.xpt" >"$tmpdir/summary"

grep -E '^Columns: 2$' "$tmpdir/summary" >/dev/null || {
  printf 'XPT summary did not pin Columns to 2\n' >&2
  cat "$tmpdir/summary" >&2
  exit 1
}
validator_assert_contains "$tmpdir/summary" 'Format: SAS transport file (XPORT)'
