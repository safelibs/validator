#!/usr/bin/env bash
# @testcase: usage-readstat-r20-sav-summary-columns-one
# @title: readstat summary of a single-column SAV reports Columns: 1
# @description: Builds a single-column CSV, converts to .sav, captures the summary output, and asserts it contains the literal "Columns: 1" - locking in the column-count summary line on the SAV writer path for a width of one.
# @timeout: 60
# @tags: usage, sav, summary, columns, r20
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
solo
1
2
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"SPSS","variables":[{"type":"NUMERIC","name":"solo","label":"S"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.sav"
readstat "$tmpdir/out.sav" >"$tmpdir/summary"

validator_assert_contains "$tmpdir/summary" 'Columns: 1'
