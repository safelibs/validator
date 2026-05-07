#!/usr/bin/env bash
# @testcase: usage-readstat-r14-sav-summary-compression-rows
# @title: readstat SAV summary reports Compression: rows by default
# @description: Builds a SAV from a CSV via DTA and verifies the readstat summary contains the literal "Compression: rows" line, locking in row-level compression as the default emitted by the readstat SAV writer on Ubuntu 24.04 — distinguishing SAV's row compression from ZSAV's binary compression.
# @timeout: 60
# @tags: usage, csv, sav, compression
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

grep -E '^Compression: rows$' "$tmpdir/summary" >/dev/null || {
  printf 'SAV summary missing literal "Compression: rows" line\n' >&2
  cat "$tmpdir/summary" >&2
  exit 1
}
# Sanity: this is a SAV summary, not ZSAV.
validator_assert_contains "$tmpdir/summary" 'Format: SPSS binary file (SAV)'
