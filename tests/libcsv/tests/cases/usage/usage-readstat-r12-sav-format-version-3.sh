#!/usr/bin/env bash
# @testcase: usage-readstat-r12-sav-format-version-3
# @title: readstat SAV writer pins Format version to 3 by default
# @description: Builds a SAV from a CSV and verifies the readstat summary reports "Format version: 3" for the SPSS binary file, locking in the SAV-version field as it appears in the metadata view on Ubuntu 24.04.
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
{"type":"SPSS","variables":[{"type":"NUMERIC","name":"id","label":"ID"},{"type":"STRING","name":"name","label":"Name"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.sav"
readstat "$tmpdir/out.sav" >"$tmpdir/summary"

validator_assert_contains "$tmpdir/summary" 'SPSS binary file (SAV)'
grep -E '^Format version: 3$' "$tmpdir/summary" >/dev/null || {
  printf 'SAV summary did not pin Format version to 3\n' >&2
  cat "$tmpdir/summary" >&2
  exit 1
}
