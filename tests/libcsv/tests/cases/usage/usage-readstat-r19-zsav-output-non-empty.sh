#!/usr/bin/env bash
# @testcase: usage-readstat-r19-zsav-output-non-empty
# @title: readstat builds a non-empty ZSAV from CSV via the DTA intermediate
# @description: Converts a small CSV through DTA into a .zsav, asserts the produced file exists with non-zero size, and runs readstat over the .zsav to capture a summary containing the ZSAV format label - locking in the ZSAV writer output path for a small two-column input.
# @timeout: 60
# @tags: usage, csv, zsav, output, r19
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
x,y
1,2
3,4
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"NUMERIC","name":"x","label":"X"},{"type":"NUMERIC","name":"y","label":"Y"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/mid.dta"
readstat "$tmpdir/mid.dta" "$tmpdir/out.zsav"

[[ -s "$tmpdir/out.zsav" ]] || {
    printf 'expected non-empty .zsav\n' >&2
    exit 1
}

readstat "$tmpdir/out.zsav" >"$tmpdir/summary"
validator_assert_contains "$tmpdir/summary" 'ZSAV'
