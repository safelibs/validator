#!/usr/bin/env bash
# @testcase: usage-readstat-overwrite-protection-without-f
# @title: readstat refuses to overwrite an existing output without -f
# @description: Generates a DTA from CSV, converts it to CSV once, then attempts the same conversion a second time without the -f flag and verifies readstat emits a "File exists (Use -f to overwrite)" diagnostic and leaves the existing output file's bytes byte-for-byte unchanged.
# @timeout: 120
# @tags: usage, csv, overwrite, safety
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
name,score
alpha,42
beta,7
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"STRING","name":"name","label":"Name"},{"type":"NUMERIC","name":"score","label":"Score"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"
readstat "$tmpdir/out.dta" "$tmpdir/out.csv"
validator_require_file "$tmpdir/out.csv"

before_hash=$(sha256sum "$tmpdir/out.csv" | awk '{print $1}')

# Second invocation without -f must report the conflict.
readstat "$tmpdir/out.dta" "$tmpdir/out.csv" >"$tmpdir/stdout" 2>"$tmpdir/stderr" || true
cat "$tmpdir/stdout" "$tmpdir/stderr" >"$tmpdir/all"

validator_assert_contains "$tmpdir/all" 'File exists'
validator_assert_contains "$tmpdir/all" '-f to overwrite'

# Existing output file must not have been altered.
after_hash=$(sha256sum "$tmpdir/out.csv" | awk '{print $1}')
if [[ "$before_hash" != "$after_hash" ]]; then
  printf 'output file unexpectedly modified: %s -> %s\n' "$before_hash" "$after_hash" >&2
  exit 1
fi
