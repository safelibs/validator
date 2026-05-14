#!/usr/bin/env bash
# @testcase: usage-readstat-r18-stdout-csv-double-quoted-header
# @title: readstat stdout CSV writer wraps each header column name in double quotes
# @description: Converts a small CSV with two named columns through DTA and back to stdout CSV, then asserts the first line of the recovered output is exactly the double-quoted comma-separated header — locking in the stdout writer's quoted-header convention.
# @timeout: 60
# @tags: usage, csv, dta, header, quote, r18
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
foo,bar
1,2
3,4
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"NUMERIC","name":"foo","label":"Foo"},{"type":"NUMERIC","name":"bar","label":"Bar"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/mid.dta"
readstat "$tmpdir/mid.dta" - >"$tmpdir/out.csv"

header=$(head -n 1 "$tmpdir/out.csv")
expected='"foo","bar"'
[[ "$header" == "$expected" ]] || {
    printf 'header mismatch: want=%s got=%s\n' "$expected" "$header" >&2
    exit 1
}
