#!/usr/bin/env bash
# @testcase: usage-readstat-r18-empty-data-rows-rejected
# @title: readstat reports zero converted rows when a CSV has only a header line
# @description: Feeds readstat a header-only CSV with no data rows and asserts the log line emits "Converted 0 variables and 0 rows" along with the "One or more columns must be provided" diagnostic — locking in the structured complaint for header-only inputs.
# @timeout: 60
# @tags: usage, csv, header-only, diagnostic, r18
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'col1,col2\n' >"$tmpdir/in.csv"

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"NUMERIC","name":"col1","label":"C1"},{"type":"NUMERIC","name":"col2","label":"C2"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta" \
    >"$tmpdir/stdout" 2>"$tmpdir/stderr" || true
cat "$tmpdir/stdout" "$tmpdir/stderr" >"$tmpdir/all"

validator_assert_contains "$tmpdir/all" 'Converted 0 variables and 0 rows'
validator_assert_contains "$tmpdir/all" 'One or more columns must be provided'
