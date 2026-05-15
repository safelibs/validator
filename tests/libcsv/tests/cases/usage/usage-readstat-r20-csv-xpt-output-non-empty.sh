#!/usr/bin/env bash
# @testcase: usage-readstat-r20-csv-xpt-output-non-empty
# @title: readstat CSV-DTA-XPT writer produces a non-empty XPT file
# @description: Builds a tiny CSV, converts to .dta via Stata metadata, then converts the .dta to a SAS Transport (.xpt) file and asserts the produced .xpt exists with positive byte length - locking in the XPT writer output path via the DTA intermediate.
# @timeout: 60
# @tags: usage, csv, xpt, output, r20
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
readstat "$tmpdir/mid.dta" "$tmpdir/out.xpt"
validator_require_file "$tmpdir/out.xpt"
n=$(wc -c <"$tmpdir/out.xpt")
[[ "$n" -gt 0 ]] || { echo 'xpt file is empty' >&2; exit 1; }
