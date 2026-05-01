#!/usr/bin/env bash
# @testcase: usage-bzgrep-files-without-match
# @title: bzgrep -L lists files without a match
# @description: Searches several .bz2 inputs with bzgrep -L and verifies only the file lacking the pattern is printed, while files containing the pattern are omitted.
# @timeout: 180
# @tags: usage, bzgrep, files-without-match
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Two files contain the needle, one does not.
printf 'alpha needle delta\n' >"$tmpdir/yes1.txt"
printf 'gamma\nneedle\nepsilon\n' >"$tmpdir/yes2.txt"
printf 'no match here\nstill nothing\n' >"$tmpdir/nope.txt"

bzip2 "$tmpdir/yes1.txt" "$tmpdir/yes2.txt" "$tmpdir/nope.txt"

# bzgrep -L prints filenames whose decompressed contents do NOT match the pattern.
( cd "$tmpdir" && bzgrep -L 'needle' yes1.txt.bz2 yes2.txt.bz2 nope.txt.bz2 ) >"$tmpdir/list.out"

# Output must be exactly the non-matching filename.
printf 'nope.txt.bz2\n' >"$tmpdir/expected"
cmp "$tmpdir/list.out" "$tmpdir/expected"

# And running -L with the same pattern against only matching files must list nothing.
( cd "$tmpdir" && bzgrep -L 'needle' yes1.txt.bz2 yes2.txt.bz2 ) >"$tmpdir/empty.out"
[[ ! -s "$tmpdir/empty.out" ]] || {
  printf 'expected empty output, got:\n' >&2
  cat "$tmpdir/empty.out" >&2
  exit 1
}
