#!/usr/bin/env bash
# @testcase: usage-readstat-r14-csv-to-zsav-summary-format-line
# @title: readstat ZSAV summary reports Format: SPSS compressed binary file (ZSAV)
# @description: Builds a ZSAV from a CSV via DTA and verifies the readstat summary contains the precise "Format: SPSS compressed binary file (ZSAV)" line and a binary compression marker, locking in the literal format-line text used by the readstat metadata view for ZSAV files on Ubuntu 24.04 — distinguishing ZSAV's binary compression from SAV's row compression.
# @timeout: 60
# @tags: usage, csv, zsav, format
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

grep -E '^Format: SPSS compressed binary file \(ZSAV\)$' "$tmpdir/summary" >/dev/null || {
  printf 'ZSAV summary missing exact Format line\n' >&2
  cat "$tmpdir/summary" >&2
  exit 1
}
# ZSAV uses binary compression (vs SAV which uses rows compression).
grep -E '^Compression: binary$' "$tmpdir/summary" >/dev/null || {
  printf 'ZSAV summary did not pin Compression to binary\n' >&2
  cat "$tmpdir/summary" >&2
  exit 1
}
