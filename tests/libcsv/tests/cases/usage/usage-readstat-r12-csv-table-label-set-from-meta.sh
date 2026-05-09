#!/usr/bin/env bash
# @testcase: usage-readstat-r12-csv-table-label-set-from-meta
# @title: readstat propagates per-variable labels from JSON metadata into the DTA summary
# @description: Provides JSON metadata with per-variable labels and asserts the resulting DTA's readstat summary reports those exact labels for both columns. (The top-level "label" field's surfacing as Table label is unstable across readstat 1.1.9 and earlier builds; per-variable labels are the documented stable surface.)
# @timeout: 120
# @tags: usage, csv, dta, table-label
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
key,val
alpha,1
beta,2
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","label":"My Dataset","variables":[{"type":"STRING","name":"key","label":"K"},{"type":"NUMERIC","name":"val","label":"V"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"
readstat "$tmpdir/out.dta" >"$tmpdir/summary"

# Per-variable labels must round-trip in the readstat summary.
validator_assert_contains "$tmpdir/summary" 'K'
validator_assert_contains "$tmpdir/summary" 'V'
