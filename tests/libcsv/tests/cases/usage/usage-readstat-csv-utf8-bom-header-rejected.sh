#!/usr/bin/env bash
# @testcase: usage-readstat-csv-utf8-bom-header-rejected
# @title: readstat does not strip UTF-8 BOM from CSV header
# @description: Prepends a UTF-8 BOM (EF BB BF) to a CSV header row and verifies readstat treats the BOM bytes as part of the first column name, fails the metadata lookup with an explicit "Could not find type of variable" diagnostic, and exits non-zero rather than silently dropping the BOM.
# @timeout: 120
# @tags: usage, csv, bom, encoding, negative
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Note: \xef\xbb\xbf is the UTF-8 BOM. The first header column is "name".
printf '\xef\xbb\xbfname,score\nalpha,42\nbeta,7\n' >"$tmpdir/in.csv"

# Sanity: file really starts with the three BOM bytes.
head_hex=$(head -c 3 "$tmpdir/in.csv" | od -An -tx1 | tr -d ' \n')
if [[ "$head_hex" != "efbbbf" ]]; then
  printf 'fixture missing BOM, head bytes=%s\n' "$head_hex" >&2
  exit 1
fi

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"STRING","name":"name","label":"Name"},{"type":"NUMERIC","name":"score","label":"Score"}]}
JSON

status=0
readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta" \
  >"$tmpdir/stdout" 2>"$tmpdir/stderr" || status=$?

cat "$tmpdir/stdout" "$tmpdir/stderr" >"$tmpdir/all"

# readstat must complain about the unknown variable rather than silently
# stripping the BOM and accepting "name".
validator_assert_contains "$tmpdir/all" 'Could not find type of variable'
validator_assert_contains "$tmpdir/all" 'name in metadata'

if [[ "$status" -eq 0 ]]; then
  printf 'expected non-zero exit when BOM corrupts header, got 0\n' >&2
  exit 1
fi
