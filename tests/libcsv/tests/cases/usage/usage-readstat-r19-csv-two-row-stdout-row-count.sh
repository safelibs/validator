#!/usr/bin/env bash
# @testcase: usage-readstat-r19-csv-two-row-stdout-row-count
# @title: readstat stdout CSV of a two-row DTA emits exactly three lines including header
# @description: Converts a two-row two-column CSV through DTA and back to stdout CSV, then asserts the recovered CSV has exactly three lines (one header plus two data rows) - locking in stdout line-count fidelity for the smallest non-trivial multi-row payload.
# @timeout: 60
# @tags: usage, csv, dta, stdout, r19
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
a,b
1,2
3,4
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"NUMERIC","name":"a","label":"A"},{"type":"NUMERIC","name":"b","label":"B"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/mid.dta"
readstat "$tmpdir/mid.dta" - >"$tmpdir/out.csv"

lines=$(wc -l <"$tmpdir/out.csv")
[[ "$lines" -eq 3 ]] || {
    printf 'expected 3 lines, got %s\n' "$lines" >&2
    cat "$tmpdir/out.csv" >&2
    exit 1
}
