#!/usr/bin/env bash
# @testcase: usage-readstat-r17-dta-stdout-csv-reparses
# @title: readstat reads its own stdout CSV back through a second conversion
# @description: Converts a CSV to .dta, then to stdout CSV, captures it as a new file, and asserts a follow-up CSV-to-DTA conversion against the captured output emits the same row/variable count log line as the original conversion — locking in stdout-csv re-readability.
# @timeout: 90
# @tags: usage, csv, dta, reparse
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
a,b
1,2
3,4
5,6
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"NUMERIC","name":"a","label":"A"},{"type":"NUMERIC","name":"b","label":"B"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/orig.dta" >"$tmpdir/log1" 2>&1
readstat "$tmpdir/orig.dta" - >"$tmpdir/reflowed.csv"
readstat "$tmpdir/reflowed.csv" "$tmpdir/meta.json" "$tmpdir/reparsed.dta" >"$tmpdir/log2" 2>&1

# Both logs should report 2 variables and 3 rows.
pat='Converted 2 variables and 3 rows in [0-9]+\.[0-9]+ seconds'
grep -E "$pat" "$tmpdir/log1" >/dev/null || {
    printf 'orig log missing expected pattern\n' >&2
    cat "$tmpdir/log1" >&2
    exit 1
}
grep -E "$pat" "$tmpdir/log2" >/dev/null || {
    printf 'reparse log missing expected pattern\n' >&2
    cat "$tmpdir/log2" >&2
    exit 1
}
