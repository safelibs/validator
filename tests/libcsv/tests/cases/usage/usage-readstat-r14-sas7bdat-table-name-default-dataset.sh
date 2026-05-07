#!/usr/bin/env bash
# @testcase: usage-readstat-r14-sas7bdat-table-name-default-dataset
# @title: readstat SAS7BDAT summary reports Table name: DATASET by default
# @description: Builds a SAS7BDAT from a CSV via DTA and verifies the readstat summary contains the canonical "Table name: DATASET" line that the SAS7BDAT writer emits in the absence of an explicit table-name override, distinguishing the SAS7BDAT default from the DTA path which has no table-name slot in its summary.
# @timeout: 60
# @tags: usage, csv, sas7bdat, table-name
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
readstat "$tmpdir/mid.dta" "$tmpdir/out.sas7bdat"
readstat "$tmpdir/out.sas7bdat" >"$tmpdir/summary"

grep -E '^Table name: DATASET$' "$tmpdir/summary" >/dev/null || {
  printf 'SAS7BDAT summary missing canonical "Table name: DATASET" line\n' >&2
  cat "$tmpdir/summary" >&2
  exit 1
}
# Sanity: this is the SAS7BDAT path, not the DTA path.
validator_assert_contains "$tmpdir/summary" 'Format: SAS data file (SAS7BDAT)'
