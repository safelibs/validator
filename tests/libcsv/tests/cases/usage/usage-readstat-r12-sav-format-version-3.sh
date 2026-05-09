#!/usr/bin/env bash
# @testcase: usage-readstat-r12-sav-format-version-3
# @title: readstat SAV writer reports a positive Format version line
# @description: Builds a SAV from a CSV and verifies the readstat summary reports "SPSS binary file" together with a "Format version: N" line where N is a positive integer. (readstat 1.1.9 emits version 2 or 3 depending on build options; either is fine — assert the line exists with a positive integer rather than pinning the exact value.)
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

validator_assert_contains "$tmpdir/summary" 'SPSS binary file'
grep -E '^Format version: [1-9][0-9]*$' "$tmpdir/summary" >/dev/null || {
  printf 'SAV summary missing positive Format version line\n' >&2
  cat "$tmpdir/summary" >&2
  exit 1
}
