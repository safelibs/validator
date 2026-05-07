#!/usr/bin/env bash
# @testcase: usage-readstat-r12-csv-table-label-set-from-meta
# @title: readstat propagates a "label" field from JSON metadata to DTA Table label
# @description: Provides JSON metadata with a top-level "label" field and asserts the resulting DTA's readstat summary reports that label rather than (null), confirming the JSON top-level label flows through the writer's dataset-label slot.
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

validator_assert_contains "$tmpdir/summary" 'My Dataset'
# Only one Table label line, and it must NOT be the (null) placeholder.
count=$(grep -cE '^Table label: ' "$tmpdir/summary")
[[ "$count" == "1" ]] || { printf 'expected exactly one Table label line\n' >&2; cat "$tmpdir/summary" >&2; exit 1; }
if grep -E '^Table label: \(null\)$' "$tmpdir/summary" >/dev/null; then
  printf 'Table label was (null), expected the JSON-supplied value\n' >&2
  cat "$tmpdir/summary" >&2
  exit 1
fi
