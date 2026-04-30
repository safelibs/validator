#!/usr/bin/env bash
# @testcase: usage-grep-include-glob
# @title: grep recursive include glob
# @description: Recursively searches a tree with grep --include="*.txt" and verifies non-matching extensions are skipped.
# @timeout: 180
# @tags: usage, grep, recursive
# @client: grep

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-grep-include-glob"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/tree/sub"
printf 'needle in txt\n' >"$tmpdir/tree/keep.txt"
printf 'needle in log\n' >"$tmpdir/tree/skip.log"
printf 'needle in nested txt\n' >"$tmpdir/tree/sub/deep.txt"

grep -r --include="*.txt" 'needle' "$tmpdir/tree" >"$tmpdir/out"

validator_assert_contains "$tmpdir/out" 'keep.txt'
validator_assert_contains "$tmpdir/out" 'deep.txt'
if grep -Fq 'skip.log' "$tmpdir/out"; then
  printf 'unexpected match in .log file\n' >&2
  cat "$tmpdir/out" >&2
  exit 1
fi
