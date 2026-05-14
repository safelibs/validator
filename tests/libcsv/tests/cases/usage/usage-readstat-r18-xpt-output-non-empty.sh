#!/usr/bin/env bash
# @testcase: usage-readstat-r18-xpt-output-non-empty
# @title: readstat builds a non-empty XPT file from CSV via the DTA intermediate
# @description: Converts a small two-column CSV through DTA to SAS XPORT format, asserts the resulting .xpt file exists with non-zero size, then runs readstat against the .xpt to capture a summary that mentions XPORT — locking in the SAS XPT writer path.
# @timeout: 60
# @tags: usage, csv, xpt, sas, r18
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
A,B
1,2
3,4
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"NUMERIC","name":"A","label":"A"},{"type":"NUMERIC","name":"B","label":"B"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/mid.dta"
readstat "$tmpdir/mid.dta" "$tmpdir/out.xpt"

[[ -s "$tmpdir/out.xpt" ]] || { printf 'expected non-empty .xpt file\n' >&2; exit 1; }

readstat "$tmpdir/out.xpt" >"$tmpdir/summary"
grep -Ei 'xport|xpt' "$tmpdir/summary" >/dev/null || {
    printf 'summary missing XPT marker\n' >&2
    cat "$tmpdir/summary" >&2
    exit 1
}
