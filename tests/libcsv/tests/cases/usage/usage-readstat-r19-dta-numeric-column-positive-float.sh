#!/usr/bin/env bash
# @testcase: usage-readstat-r19-dta-numeric-column-positive-float
# @title: readstat preserves a positive decimal cell 1.5 through the CSV-DTA-CSV roundtrip
# @description: Converts a single-row CSV containing the value 1.5 through DTA and back to stdout CSV, then asserts the lone data row equals "1.500000" - locking in fractional decimal rendering at the readstat six-decimal default.
# @timeout: 60
# @tags: usage, csv, dta, decimal, r19
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
v
1.5
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"NUMERIC","name":"v","label":"V"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/mid.dta"
readstat "$tmpdir/mid.dta" - >"$tmpdir/out.csv"

data=$(sed -n '2p' "$tmpdir/out.csv")
[[ "$data" == "1.500000" ]] || {
    printf 'expected "1.500000", got %q\n' "$data" >&2
    cat "$tmpdir/out.csv" >&2
    exit 1
}
