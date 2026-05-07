#!/usr/bin/env bash
# @testcase: usage-readstat-r15-xpt-omits-byte-order-line
# @title: readstat XPT summary intentionally omits the Byte order line
# @description: Builds an XPT from a CSV via DTA and asserts the readstat summary contains NO line beginning with "Byte order:" — locking in the well-known XPT-specific shape where SAS XPORT files do not carry a runtime byte-order field, in contrast to DTA, SAV, ZSAV, and SAS7BDAT which all emit a Byte order line. Asserts the absence with -c 0.
# @timeout: 60
# @tags: usage, csv, xpt, byte-order, negative
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

count=$(grep -cE '^Byte order:' "$tmpdir/summary" || true)
[[ "$count" == "0" ]] || {
  printf 'XPT summary unexpectedly contains a Byte order line (count=%s)\n' "$count" >&2
  cat "$tmpdir/summary" >&2
  exit 1
}
