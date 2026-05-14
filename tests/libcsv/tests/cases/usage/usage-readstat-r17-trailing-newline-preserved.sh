#!/usr/bin/env bash
# @testcase: usage-readstat-r17-trailing-newline-preserved
# @title: readstat stdout CSV output ends with a trailing newline
# @description: Converts a small CSV to .dta and back to stdout CSV, then asserts the last byte of the recovered stream is a newline (0x0a) — locking in the trailing-newline contract of readstat's stdout CSV writer.
# @timeout: 60
# @tags: usage, csv, dta, trailing-newline
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

last_byte=$(tail -c 1 "$tmpdir/out.csv" | od -An -tx1 | tr -d ' \n')
[[ "$last_byte" == "0a" ]] || {
    printf 'expected trailing newline (0a), got %s\n' "$last_byte" >&2
    od -c "$tmpdir/out.csv" | tail -3 >&2
    exit 1
}
