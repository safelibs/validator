#!/usr/bin/env bash
# @testcase: usage-readstat-r21-csv-stdout-header-present
# @title: readstat CSV stdout output begins with quoted header column name
# @description: Converts a two-row CSV through DTA and asserts the very first line of the stdout CSV is the quoted header `"vname"` (matching readstat's header-quoting convention) - locking in header emission on the stdout dash output distinct from existing header-line tests which check column count or three-column shapes.
# @timeout: 60
# @tags: usage, csv, dta, stdout-header, r21
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
vname
7
8
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"NUMERIC","name":"vname","label":"V"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/mid.dta"
readstat "$tmpdir/mid.dta" - >"$tmpdir/out.csv"

first=$(head -n 1 "$tmpdir/out.csv")
[[ "$first" == '"vname"' ]] || {
    printf 'expected first line to be "vname", got %q\n' "$first" >&2
    head -n 3 "$tmpdir/out.csv" >&2
    exit 1
}
