#!/usr/bin/env bash
# @testcase: usage-readstat-r19-stdout-csv-trailing-newline
# @title: readstat stdout CSV output ends with a trailing newline byte
# @description: Converts a two-row CSV through DTA back to stdout CSV redirected to a file, reads the last byte of that file, and asserts it is the LF (0x0a) character - locking in stdout CSV terminator behavior of the readstat client.
# @timeout: 60
# @tags: usage, csv, dta, stdout, newline, r19
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
v
1
2
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"NUMERIC","name":"v","label":"V"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/mid.dta"
readstat "$tmpdir/mid.dta" - >"$tmpdir/out.csv"

last_byte=$(tail -c 1 "$tmpdir/out.csv" | od -An -tx1 | tr -d ' \n')
[[ "$last_byte" == "0a" ]] || {
    printf 'expected trailing LF (0a), got %q\n' "$last_byte" >&2
    od -c "$tmpdir/out.csv" | tail -3 >&2
    exit 1
}
