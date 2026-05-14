#!/usr/bin/env bash
# @testcase: usage-readstat-r17-sav-summary-format-line-present
# @title: readstat SAV summary includes a Format-version line with any positive integer
# @description: Builds a SAV from a small CSV and asserts the summary contains an "SPSS" marker plus any Format-version line with a positive integer, deliberately accepting noble's actual emitted value (version 2) rather than pinning the exact number.
# @timeout: 60
# @tags: usage, csv, sav, version
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
id,n
1,10
2,20
3,30
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"SPSS","variables":[{"type":"NUMERIC","name":"id","label":"ID"},{"type":"NUMERIC","name":"n","label":"N"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.sav"
readstat "$tmpdir/out.sav" >"$tmpdir/summary"

grep -Ei 'spss' "$tmpdir/summary" >/dev/null || {
    printf 'summary missing SPSS marker\n' >&2
    cat "$tmpdir/summary" >&2
    exit 1
}
grep -E '^Format version: [1-9][0-9]*$' "$tmpdir/summary" >/dev/null || {
    printf 'summary missing positive Format version line\n' >&2
    cat "$tmpdir/summary" >&2
    exit 1
}
