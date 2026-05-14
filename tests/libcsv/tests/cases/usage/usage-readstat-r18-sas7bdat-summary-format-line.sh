#!/usr/bin/env bash
# @testcase: usage-readstat-r18-sas7bdat-summary-format-line
# @title: readstat SAS7BDAT summary carries the SAS7BDAT format label
# @description: Builds a SAS7BDAT from a small two-column CSV via the DTA intermediate path and asserts the summary contains a "Format:" line mentioning SAS7BDAT — locking in the SAS binary writer's format-label emission.
# @timeout: 60
# @tags: usage, csv, sas7bdat, format, r18
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
readstat "$tmpdir/mid.dta" "$tmpdir/out.sas7bdat"
readstat "$tmpdir/out.sas7bdat" >"$tmpdir/summary"

grep -E '^Format:.*SAS7BDAT' "$tmpdir/summary" >/dev/null || {
    printf 'expected Format line mentioning SAS7BDAT\n' >&2
    cat "$tmpdir/summary" >&2
    exit 1
}
