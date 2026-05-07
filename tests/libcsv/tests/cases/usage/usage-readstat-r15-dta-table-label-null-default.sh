#!/usr/bin/env bash
# @testcase: usage-readstat-r15-dta-table-label-null-default
# @title: readstat DTA summary reports Table label: (null) when no label is set
# @description: Builds a DTA from a CSV with no explicit dataset label and verifies the readstat summary contains the literal "Table label: (null)" line — locking in that the readstat DTA writer leaves the dataset-label slot null and the metadata view formats null as the literal string "(null)" on Ubuntu 24.04 readstat 1.1.9. Distinct from the table-name line emitted by the SAS7BDAT and XPT paths.
# @timeout: 60
# @tags: usage, csv, dta, table-label
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
grep -E '^Table label: \(null\)$' "$tmpdir/summary" >/dev/null || {
  printf 'DTA summary missing literal "Table label: (null)" line\n' >&2
  cat "$tmpdir/summary" >&2
  exit 1
}
