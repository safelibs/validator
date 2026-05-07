#!/usr/bin/env bash
# @testcase: usage-readstat-r13-dta-summary-byte-order-line
# @title: readstat DTA summary reports Byte order: little-endian by default
# @description: Builds a DTA from a CSV with no byte-order override and verifies the readstat summary contains the literal "Byte order: little-endian" line, locking in little-endian as the default byte order emitted by the readstat DTA writer on Ubuntu 24.04 — distinguishing the byte-order line from the format-version line and exercising the DTA path specifically.
# @timeout: 60
# @tags: usage, csv, dta, byte-order
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
grep -E '^Byte order: little-endian$' "$tmpdir/summary" >/dev/null || {
  printf 'DTA summary missing literal "Byte order: little-endian" line\n' >&2
  cat "$tmpdir/summary" >&2
  exit 1
}
# Exactly one Byte order line.
count=$(grep -cE '^Byte order: ' "$tmpdir/summary")
[[ "$count" == "1" ]] || {
  printf 'expected exactly one Byte order line, got %s\n' "$count" >&2
  cat "$tmpdir/summary" >&2
  exit 1
}
