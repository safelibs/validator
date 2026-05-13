#!/usr/bin/env bash
# @testcase: usage-readstat-r16-por-format-version-line
# @title: readstat POR summary reports an SPSS portable format-version line
# @description: Converts a small CSV to .por via SAV, reads back the .por summary, and asserts the summary contains a "Format:" line that mentions SPSS portable — locking in readstat's portable-write surface without committing to a specific version number text.
# @timeout: 120
# @tags: usage, csv, por, format
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
id,score
1,10
2,20
3,30
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"SPSS","variables":[{"type":"NUMERIC","name":"id","label":"ID"},{"type":"NUMERIC","name":"score","label":"Score"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/mid.sav"
readstat "$tmpdir/mid.sav" "$tmpdir/out.por"
readstat "$tmpdir/out.por" >"$tmpdir/summary"

validator_assert_contains "$tmpdir/summary" 'Format:'
grep -Ei 'spss.*portable|portable.*spss|\.por' "$tmpdir/summary" >/dev/null || {
    printf 'POR summary missing portable marker\n' >&2
    cat "$tmpdir/summary" >&2
    exit 1
}
