#!/usr/bin/env bash
# @testcase: usage-readstat-csv-mismatched-metadata-variable-rejected
# @title: readstat rejects metadata that does not list a CSV column
# @description: Supplies a CSV header with columns "n,v" but a JSON metadata file that lists "foobar,v", and verifies readstat exits non-zero with "Could not find type of variable n in metadata", proving readstat validates that every CSV column has a metadata entry rather than silently typing the unknown column.
# @timeout: 120
# @tags: usage, csv, metadata, negative
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
n,v
alpha,1
beta,2
CSV

# Metadata names "foobar" instead of "n".
cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"STRING","name":"foobar","label":"X"},{"type":"NUMERIC","name":"v","label":"V"}]}
JSON

status=0
readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta" \
  >"$tmpdir/stdout" 2>"$tmpdir/stderr" || status=$?
cat "$tmpdir/stdout" "$tmpdir/stderr" >"$tmpdir/all"

if [[ "$status" -eq 0 ]]; then
  printf 'expected non-zero exit on metadata mismatch, got 0\n' >&2
  cat "$tmpdir/all" >&2
  exit 1
fi

validator_assert_contains "$tmpdir/all" 'Could not find type of variable'
validator_assert_contains "$tmpdir/all" 'n in metadata'
