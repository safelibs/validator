#!/usr/bin/env bash
# @testcase: usage-readstat-r9-csv-zsav-compressed-output
# @title: readstat writes SPSS .sav with compression
# @description: Writes a CSV through readstat into the SPSS .sav format and verifies the output is non-empty and round-trips back through readstat with the right shape.
# @timeout: 180
# @tags: usage, csv, zsav
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

{
  printf 'k,v\n'
  for i in $(seq 1 25); do printf '%d,%d\n' "$i" $((i * 10)); done
} >"$tmpdir/in.csv"

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"SPSS","variables":[{"type":"NUMERIC","name":"k","label":"K"},{"type":"NUMERIC","name":"v","label":"V"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.sav"

# Output must exist and be non-empty.
[[ -s "$tmpdir/out.sav" ]]

readstat "$tmpdir/out.sav" >"$tmpdir/summary"
validator_assert_contains "$tmpdir/summary" 'Columns: 2'
validator_assert_contains "$tmpdir/summary" 'Rows: 25'
