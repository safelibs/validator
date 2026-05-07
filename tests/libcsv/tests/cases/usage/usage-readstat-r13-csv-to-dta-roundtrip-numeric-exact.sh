#!/usr/bin/env bash
# @testcase: usage-readstat-r13-csv-to-dta-roundtrip-numeric-exact
# @title: readstat CSV to DTA to CSV preserves a 1.000000 numeric value exactly
# @description: Round-trips a CSV row whose numeric column carries the integer 1 through DTA and back to CSV via the dash stdout target, and asserts the readback CSV renders the value as the canonical six-decimal fixed-point form "1.000000" rather than the bare integer or a scientific-notation form.
# @timeout: 60
# @tags: usage, csv, dta, numeric, roundtrip
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
id,score
1,42
2,7
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"NUMERIC","name":"id","label":"ID"},{"type":"NUMERIC","name":"score","label":"Score"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/mid.dta"
readstat "$tmpdir/mid.dta" - >"$tmpdir/out.csv"

# Header line first, then rows in the original order, with numeric values in
# the canonical 6-decimal fixed-point form.
head -1 "$tmpdir/out.csv" >"$tmpdir/header"
validator_assert_contains "$tmpdir/header" '"id","score"'

validator_assert_contains "$tmpdir/out.csv" '1.000000,42.000000'
validator_assert_contains "$tmpdir/out.csv" '2.000000,7.000000'
# No scientific notation or alternate forms.
if grep -E '[eE][+-]?[0-9]' "$tmpdir/out.csv" >/dev/null; then
  printf 'numeric field rendered with scientific notation\n' >&2
  cat "$tmpdir/out.csv" >&2
  exit 1
fi
