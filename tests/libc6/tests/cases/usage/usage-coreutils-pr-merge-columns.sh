#!/usr/bin/env bash
# @testcase: usage-coreutils-pr-merge-columns
# @title: coreutils pr merge columns
# @description: Merges two text files side-by-side with pr -mt and verifies tokens from both files appear on the same line.
# @timeout: 180
# @tags: usage, coreutils, format
# @client: coreutils

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-coreutils-pr-merge-columns"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'left1\nleft2\n' >"$tmpdir/a.txt"
printf 'right1\nright2\n' >"$tmpdir/b.txt"

pr -mt "$tmpdir/a.txt" "$tmpdir/b.txt" >"$tmpdir/out"

grep -Fq 'left1' "$tmpdir/out" || { cat "$tmpdir/out" >&2; exit 1; }
grep -Fq 'right1' "$tmpdir/out" || { cat "$tmpdir/out" >&2; exit 1; }

# left1 and right1 must appear on the same line
grep -Eq 'left1[[:space:]]+right1' "$tmpdir/out" || {
  printf 'expected left1 and right1 on the same line\n' >&2
  cat "$tmpdir/out" >&2
  exit 1
}
