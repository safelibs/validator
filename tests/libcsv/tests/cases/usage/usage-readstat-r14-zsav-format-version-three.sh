#!/usr/bin/env bash
# @testcase: usage-readstat-r14-zsav-format-version-three
# @title: readstat ZSAV summary reports Format version: 3 (vs SAV's 2)
# @description: Builds a ZSAV from a CSV via DTA and verifies the readstat summary contains the precise "Format version: 3" line, locking in that ZSAV files use SPSS layout version 3 in contrast to plain SAV files which use version 2 on Ubuntu 24.04 readstat 1.1.9.
# @timeout: 60
# @tags: usage, csv, zsav, format-version
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
readstat "$tmpdir/mid.dta" "$tmpdir/out.zsav"
readstat "$tmpdir/out.sav" >"$tmpdir/sav.summary"
readstat "$tmpdir/out.zsav" >"$tmpdir/zsav.summary"

grep -E '^Format version: 2$' "$tmpdir/sav.summary" >/dev/null || {
  printf 'expected SAV Format version 2\n' >&2; cat "$tmpdir/sav.summary" >&2; exit 1; }
grep -E '^Format version: 3$' "$tmpdir/zsav.summary" >/dev/null || {
  printf 'expected ZSAV Format version 3\n' >&2; cat "$tmpdir/zsav.summary" >&2; exit 1; }
