#!/usr/bin/env bash
# @testcase: usage-readstat-r21-csv-sas7bdat-rowcount-six
# @title: readstat CSV-to-SAS7BDAT preserves six rows on stdout CSV readback
# @description: Builds a six-row CSV, converts through .dta to .sas7bdat, reads back to stdout CSV, and asserts the recovered output has exactly seven non-empty lines (one header + six data rows) - locking in SAS7BDAT row-count fidelity on six-row input distinct from prior summary-rows tests.
# @timeout: 60
# @tags: usage, sas7bdat, rowcount, r21
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
v
1
2
3
4
5
6
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"NUMERIC","name":"v","label":"V"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/mid.dta"
readstat "$tmpdir/mid.dta" "$tmpdir/out.sas7bdat"
readstat "$tmpdir/out.sas7bdat" - >"$tmpdir/back.csv"

n=$(LC_ALL=C grep -cE '[^[:space:]]' "$tmpdir/back.csv" || true)
[[ "$n" -eq 7 ]] || {
    printf 'expected 7 non-empty lines, got %s\n' "$n" >&2
    cat "$tmpdir/back.csv" >&2
    exit 1
}
