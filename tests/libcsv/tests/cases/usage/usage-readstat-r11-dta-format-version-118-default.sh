#!/usr/bin/env bash
# @testcase: usage-readstat-r11-dta-format-version-118-default
# @title: readstat DTA writer pins Format version to 118 by default
# @description: Builds a DTA from a CSV with no version override and verifies the readstat summary reports "Format version: 118" rather than leaving the version field unpinned, locking in the Stata 14+ wire format as the default DTA version emitted by the readstat writer on Ubuntu 24.04.
# @timeout: 60
# @tags: usage, csv, dta, format-version
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

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"
readstat "$tmpdir/out.dta" >"$tmpdir/summary"

validator_assert_contains "$tmpdir/summary" 'Format: Stata binary file (DTA)'
grep -E '^Format version: 118$' "$tmpdir/summary" >/dev/null || {
  printf 'DTA summary did not pin Format version to 118\n' >&2
  cat "$tmpdir/summary" >&2
  exit 1
}
