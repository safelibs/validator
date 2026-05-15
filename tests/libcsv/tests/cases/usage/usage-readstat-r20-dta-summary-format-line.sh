#!/usr/bin/env bash
# @testcase: usage-readstat-r20-dta-summary-format-line
# @title: readstat summary of a DTA file emits a Format: line referencing Stata
# @description: Converts a tiny CSV to .dta via Stata metadata, captures the summary output for the .dta file, and asserts it contains a line starting with "Format:" - locking in the format-line summary path on the DTA reader.
# @timeout: 60
# @tags: usage, dta, summary, format, r20
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
v
7
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"NUMERIC","name":"v","label":"V"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"
readstat "$tmpdir/out.dta" >"$tmpdir/summary"

LC_ALL=C grep -Eq '^Format:' "$tmpdir/summary" || {
    echo 'no Format: line in summary' >&2
    cat "$tmpdir/summary" >&2
    exit 1
}
