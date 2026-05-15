#!/usr/bin/env bash
# @testcase: usage-readstat-r19-sas7bdat-output-non-empty
# @title: readstat writes a non-empty SAS7BDAT file from CSV via the DTA intermediate
# @description: Converts a two-row two-column CSV through DTA and into a .sas7bdat file, asserts the produced file exists with non-zero size, and runs readstat over the .sas7bdat to capture a summary containing the SAS7BDAT format label - locking in the SAS7BDAT writer output path with two numeric columns.
# @timeout: 60
# @tags: usage, csv, sas7bdat, output, r19
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
m,n
1,2
3,4
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"NUMERIC","name":"m","label":"M"},{"type":"NUMERIC","name":"n","label":"N"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/mid.dta"
readstat "$tmpdir/mid.dta" "$tmpdir/out.sas7bdat"

[[ -s "$tmpdir/out.sas7bdat" ]] || {
    printf 'expected non-empty .sas7bdat\n' >&2
    exit 1
}

readstat "$tmpdir/out.sas7bdat" >"$tmpdir/summary"
validator_assert_contains "$tmpdir/summary" 'SAS7BDAT'
