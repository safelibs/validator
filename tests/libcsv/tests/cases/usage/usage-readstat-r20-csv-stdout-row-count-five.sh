#!/usr/bin/env bash
# @testcase: usage-readstat-r20-csv-stdout-row-count-five
# @title: readstat CSV-DTA stdout reader emits five data lines plus one header
# @description: Builds a CSV with five data rows, converts to .dta, then reads it back to stdout CSV, and asserts the output has exactly six total non-empty lines (one header + five data) - locking in the row-count fidelity through the stdout CSV writer.
# @timeout: 60
# @tags: usage, csv, dta, stdout, rowcount, r20
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
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"NUMERIC","name":"v","label":"V"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/mid.dta"
readstat "$tmpdir/mid.dta" - >"$tmpdir/out.csv"

n=$(LC_ALL=C grep -cE '[^[:space:]]' "$tmpdir/out.csv" || true)
[[ "$n" -eq 6 ]] || {
    printf 'expected 6 non-empty lines, got %s\n' "$n" >&2
    cat "$tmpdir/out.csv" >&2
    exit 1
}
