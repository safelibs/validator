#!/usr/bin/env bash
# @testcase: usage-readstat-r12-csv-to-zsav-file-suffix
# @title: readstat csv -> .zsav produces an SPSS binary file with compressed marker
# @description: Converts a CSV directly to a .zsav target and verifies the readstat summary identifies the resulting file as an SPSS binary file and reports a compression marker distinguishing it from an uncompressed .sav, locking in zsav extension routing through the SPSS writer with compression enabled.
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

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.zsav"
validator_require_file "$tmpdir/out.zsav"
readstat "$tmpdir/out.zsav" >"$tmpdir/summary"

validator_assert_contains "$tmpdir/summary" 'SPSS binary file'
# Compression marker should mention compressed/zsav-style indicator.
grep -iE 'compress' "$tmpdir/summary" >/dev/null || {
  printf 'zsav summary missing compression marker\n' >&2
  cat "$tmpdir/summary" >&2
  exit 1
}
