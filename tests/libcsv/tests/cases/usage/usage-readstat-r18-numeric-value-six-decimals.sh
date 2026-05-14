#!/usr/bin/env bash
# @testcase: usage-readstat-r18-numeric-value-six-decimals
# @title: readstat stdout CSV renders integer cells as N.000000 with six decimal places
# @description: Converts a CSV with a single integer column through DTA and back to stdout CSV, then asserts the lone data row equals "7.000000" — locking in the six-decimal default rendering of numeric cells for integer inputs.
# @timeout: 60
# @tags: usage, csv, dta, numeric, decimals, r18
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
value
7
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"NUMERIC","name":"value","label":"V"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/mid.dta"
readstat "$tmpdir/mid.dta" - >"$tmpdir/out.csv"

data=$(sed -n '2p' "$tmpdir/out.csv")
[[ "$data" == "7.000000" ]] || {
    printf 'expected "7.000000", got %q\n' "$data" >&2
    cat "$tmpdir/out.csv" >&2
    exit 1
}
