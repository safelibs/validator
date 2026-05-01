#!/usr/bin/env bash
# @testcase: usage-readstat-force-flag-overwrites-existing
# @title: readstat -f flag overwrites a pre-existing output file
# @description: Generates a DTA from a CSV, runs readstat once to produce out.csv, then re-runs the same conversion with -f and verifies the second invocation succeeds quietly, leaves no "File exists" diagnostic, and that the output file's mtime advances (proving it was rewritten rather than skipped).
# @timeout: 120
# @tags: usage, csv, force, overwrite
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

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/mid.dta"
readstat "$tmpdir/mid.dta" "$tmpdir/out.csv"
validator_require_file "$tmpdir/out.csv"

# Backdate the file so a later mtime is unambiguous.
touch -d '2000-01-01 00:00:00' "$tmpdir/out.csv"
before_mtime=$(stat -c %Y "$tmpdir/out.csv")

# Re-run with -f to force overwrite.
readstat -f "$tmpdir/mid.dta" "$tmpdir/out.csv" \
  >"$tmpdir/stdout" 2>"$tmpdir/stderr"
cat "$tmpdir/stdout" "$tmpdir/stderr" >"$tmpdir/all"

# No conflict diagnostic must appear.
if grep -F 'File exists' "$tmpdir/all" >/dev/null; then
  printf 'unexpected "File exists" diagnostic with -f\n' >&2
  cat "$tmpdir/all" >&2
  exit 1
fi
if grep -F '-f to overwrite' "$tmpdir/all" >/dev/null; then
  printf 'unexpected overwrite hint with -f\n' >&2
  cat "$tmpdir/all" >&2
  exit 1
fi

# Output must look like a real readstat CSV result.
validator_assert_contains "$tmpdir/out.csv" '"name","score"'
validator_assert_contains "$tmpdir/out.csv" '"alpha",42.000000'

after_mtime=$(stat -c %Y "$tmpdir/out.csv")
if [[ "$after_mtime" -le "$before_mtime" ]]; then
  printf 'mtime did not advance after -f rewrite: before=%s after=%s\n' \
    "$before_mtime" "$after_mtime" >&2
  exit 1
fi
