#!/usr/bin/env bash
# @testcase: usage-readstat-r12-xpt-table-name-default-dataset
# @title: readstat XPT summary reports Table name: DATASET by default
# @description: Builds an XPT from a CSV via DTA and verifies the readstat summary contains the canonical "Table name: DATASET" line that the XPT writer emits in the absence of an explicit table-name override, distinguishing XPT defaults from formats that use the dataset label slot instead.
# @timeout: 60
# @tags: usage, csv, xpt, table-name
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

grep -E '^Table name: DATASET$' "$tmpdir/summary" >/dev/null || {
  printf 'XPT summary missing canonical "Table name: DATASET" line\n' >&2
  cat "$tmpdir/summary" >&2
  exit 1
}
