#!/usr/bin/env bash
# @testcase: usage-readstat-r12-csv-to-stdout-dash-target
# @title: readstat dta - writes CSV body to stdout
# @description: Uses the documented "-" output target with a DTA input and asserts the CSV body lands on stdout (file descriptor 1) with the expected header and data rows, exercising the dump-to-stdout entry point distinct from a named .csv output file.
# @timeout: 60
# @tags: usage, csv, dta, stdout
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
id,name
1,alice
2,bob
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"NUMERIC","name":"id","label":"ID"},{"type":"STRING","name":"name","label":"Name"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/mid.dta"
readstat "$tmpdir/mid.dta" - >"$tmpdir/stdout.csv"

validator_assert_contains "$tmpdir/stdout.csv" '"id","name"'
validator_assert_contains "$tmpdir/stdout.csv" '"alice"'
validator_assert_contains "$tmpdir/stdout.csv" '"bob"'
line_count=$(wc -l <"$tmpdir/stdout.csv")
[[ "$line_count" -ge 3 ]] || { printf 'expected at least 3 stdout lines, got %s\n' "$line_count" >&2; exit 1; }
