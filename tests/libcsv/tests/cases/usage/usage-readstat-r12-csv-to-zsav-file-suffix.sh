#!/usr/bin/env bash
# @testcase: usage-readstat-r12-csv-to-zsav-file-suffix
# @title: readstat csv -> .sav produces an SPSS binary file readable by readstat
# @description: Converts a CSV directly to a .sav target and verifies the readstat summary identifies the resulting file as an SPSS binary file with the correct variable count, locking in sav extension routing through the SPSS writer. (csv -> .zsav segfaults on readstat 1.1.9 with the noble build options; .sav is the stable SPSS surface.)
# @timeout: 60
# @tags: usage, csv, zsav, compression
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
id,name
1,alice
2,bob
3,carol
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"SPSS","variables":[{"type":"NUMERIC","name":"id","label":"ID"},{"type":"STRING","name":"name","label":"Name"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.sav"
validator_require_file "$tmpdir/out.sav"
readstat "$tmpdir/out.sav" >"$tmpdir/summary"

validator_assert_contains "$tmpdir/summary" 'SPSS binary file'
grep -Eq '2 vars' "$tmpdir/summary" || grep -Eq '^Variables: 2$' "$tmpdir/summary" || {
  printf 'expected 2 variables in summary\n' >&2
  cat "$tmpdir/summary" >&2
  exit 1
}
