#!/usr/bin/env bash
# @testcase: usage-readstat-csv-8000-row-streaming-roundtrip
# @title: readstat streams an 8000-row CSV through DTA and back
# @description: Generates an 8000-row two-column CSV with monotonically increasing values, converts to DTA, reads it back to CSV via the "-" stdout sink, and verifies the DTA summary reports exactly 8000 rows, the readback produces 8001 lines (header + rows), and the first/middle/last data rows survive numerically. Stresses libreadstat's CSV streaming path with a row count larger than typical buffered batches.
# @timeout: 240
# @tags: usage, csv, streaming, large
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

{
  printf 'row,value\n'
  for i in $(seq 1 8000); do
    printf '%s,%s\n' "$i" "$((i * 2))"
  done
} >"$tmpdir/in.csv"

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"NUMERIC","name":"row","label":"Row"},{"type":"NUMERIC","name":"value","label":"Value"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"
validator_require_file "$tmpdir/out.dta"

readstat "$tmpdir/out.dta" >"$tmpdir/summary"
validator_assert_contains "$tmpdir/summary" 'Columns: 2'
validator_assert_contains "$tmpdir/summary" 'Rows: 8000'

readstat "$tmpdir/out.dta" - >"$tmpdir/out.csv"
line_count=$(wc -l <"$tmpdir/out.csv")
if [[ "$line_count" -ne 8001 ]]; then
  printf 'expected 8001 lines (header + 8000 rows), got %s\n' "$line_count" >&2
  exit 1
fi

validator_assert_contains "$tmpdir/out.csv" '"row","value"'
# First, middle, and last data rows.
validator_assert_contains "$tmpdir/out.csv" '1.000000,2.000000'
validator_assert_contains "$tmpdir/out.csv" '4000.000000,8000.000000'
validator_assert_contains "$tmpdir/out.csv" '8000.000000,16000.000000'
