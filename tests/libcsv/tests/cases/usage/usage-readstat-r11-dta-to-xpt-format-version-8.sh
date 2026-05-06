#!/usr/bin/env bash
# @testcase: usage-readstat-r11-dta-to-xpt-format-version-8
# @title: readstat dta-to-xpt summary pins Format version to 8
# @description: Builds an XPT from a CSV via DTA and verifies the readstat summary reports the SAS Transport file format with the specific "Format version: 8" line that locks in XPT v8 as the format version emitted by the readstat XPT writer on Ubuntu 24.04.
# @timeout: 60
# @tags: usage, csv, xpt, format-version
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

validator_assert_contains "$tmpdir/summary" 'Format: SAS transport file (XPORT)'
grep -E '^Format version: 8$' "$tmpdir/summary" >/dev/null || {
  printf 'XPT summary did not pin Format version to 8\n' >&2
  cat "$tmpdir/summary" >&2
  exit 1
}
