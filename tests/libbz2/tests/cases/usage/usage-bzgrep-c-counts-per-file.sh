#!/usr/bin/env bash
# @testcase: usage-bzgrep-c-counts-per-file
# @title: bzgrep -c reports per-file match counts
# @description: Searches three compressed files with bzgrep -c and verifies the emitted output is a "filename:count" line per input, with the per-file counts matching the constructed match distribution (3, 0, 5).
# @timeout: 180
# @tags: usage, bzgrep, count
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Three files: 3 hits, 0 hits, 5 hits.
printf 'needle\nfoo\nneedle\nbar\nneedle\n' >"$tmpdir/three.txt"
printf 'apple\nbanana\ncherry\n' >"$tmpdir/zero.txt"
printf 'needle\nneedle\nneedle\nneedle\nneedle\n' >"$tmpdir/five.txt"

bzip2 -zk "$tmpdir/three.txt"
bzip2 -zk "$tmpdir/zero.txt"
bzip2 -zk "$tmpdir/five.txt"

# bzgrep returns the worst per-file grep status (1 because zero.txt has no matches).
set +e
( cd "$tmpdir" && bzgrep -c needle three.txt.bz2 zero.txt.bz2 five.txt.bz2 ) >"$tmpdir/out"
rc=$?
set -e
if (( rc >= 2 )); then
  printf 'bzgrep -c failed with exit %s\n' "$rc" >&2
  sed -n '1,20p' "$tmpdir/out" >&2
  exit 1
fi

# Output must be exactly three lines (one per input file).
line_count=$(wc -l <"$tmpdir/out")
[[ "$line_count" -eq 3 ]] || {
  printf 'expected 3 output lines, got %s\n' "$line_count" >&2
  sed -n '1,20p' "$tmpdir/out" >&2
  exit 1
}

# Each line must be exactly "filename.bz2:count".
grep -Fxq 'three.txt.bz2:3' "$tmpdir/out" || {
  printf 'missing three.txt.bz2:3 line\n' >&2
  sed -n '1,20p' "$tmpdir/out" >&2
  exit 1
}
grep -Fxq 'zero.txt.bz2:0' "$tmpdir/out" || {
  printf 'missing zero.txt.bz2:0 line\n' >&2
  sed -n '1,20p' "$tmpdir/out" >&2
  exit 1
}
grep -Fxq 'five.txt.bz2:5' "$tmpdir/out" || {
  printf 'missing five.txt.bz2:5 line\n' >&2
  sed -n '1,20p' "$tmpdir/out" >&2
  exit 1
}
