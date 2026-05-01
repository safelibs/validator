#!/usr/bin/env bash
# @testcase: usage-bzdiff-brief-q-flag
# @title: bzdiff -q reports differing files briefly
# @description: Runs bzdiff -q (brief mode) on identical and differing compressed inputs and verifies the report mentions the differing files without emitting full diff hunks.
# @timeout: 180
# @tags: usage, bzdiff, brief
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'shared header\nbody1\nbody2\n' >"$tmpdir/left.txt"
cp "$tmpdir/left.txt" "$tmpdir/same.txt"
printf 'shared header\nDIFFERENT BODY\nbody2\n' >"$tmpdir/right.txt"

bzip2 -k "$tmpdir/left.txt"
bzip2 -k "$tmpdir/same.txt"
bzip2 -k "$tmpdir/right.txt"

# Identical inputs - bzdiff -q must produce no output and exit 0.
status=0
bzdiff -q "$tmpdir/left.txt.bz2" "$tmpdir/same.txt.bz2" \
  >"$tmpdir/eq.out" 2>"$tmpdir/eq.err" || status=$?
[[ "$status" -eq 0 ]] || {
  printf 'expected exit 0 for identical inputs, got %s\n' "$status" >&2
  exit 1
}
[[ ! -s "$tmpdir/eq.out" ]] || { printf '-q emitted output for identical inputs\n' >&2; cat "$tmpdir/eq.out" >&2; exit 1; }

# Differing inputs - bzdiff -q must mention both file paths and exit 1.
status=0
bzdiff -q "$tmpdir/left.txt.bz2" "$tmpdir/right.txt.bz2" \
  >"$tmpdir/diff.out" 2>"$tmpdir/diff.err" || status=$?
[[ "$status" -eq 1 ]] || {
  printf 'expected exit 1 for differing inputs, got %s\n' "$status" >&2
  exit 1
}
validator_assert_contains "$tmpdir/diff.out" "left.txt.bz2"
validator_assert_contains "$tmpdir/diff.out" "right.txt.bz2"

# Brief mode must NOT include full diff hunks (no leading '<' or '>' lines, no '---').
if grep -qE '^[<>] ' "$tmpdir/diff.out"; then
  printf 'bzdiff -q unexpectedly emitted full diff hunks:\n' >&2
  cat "$tmpdir/diff.out" >&2
  exit 1
fi
