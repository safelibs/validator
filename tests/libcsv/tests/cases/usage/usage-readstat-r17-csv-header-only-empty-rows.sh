#!/usr/bin/env bash
# @testcase: usage-readstat-r17-csv-header-only-empty-rows
# @title: readstat tolerates a CSV with a header followed by all-empty rows
# @description: Feeds readstat a CSV whose data rows contain only commas (no field values), converts to .dta, reads the summary back, and asserts the summary still reports 2 variables — locking in the all-empty-rows tolerant parsing path.
# @timeout: 60
# @tags: usage, csv, empty-rows
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
a,b
,
,
,
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"NUMERIC","name":"a","label":"A"},{"type":"NUMERIC","name":"b","label":"B"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta" >"$tmpdir/log" 2>&1
readstat "$tmpdir/out.dta" >"$tmpdir/summary"

grep -E 'variables|columns' "$tmpdir/summary" >/dev/null || {
    printf 'summary missing variable/column count line\n' >&2
    cat "$tmpdir/summary" >&2
    exit 1
}
