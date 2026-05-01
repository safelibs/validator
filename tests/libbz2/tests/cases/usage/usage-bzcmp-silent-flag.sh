#!/usr/bin/env bash
# @testcase: usage-bzcmp-silent-flag
# @title: bzcmp -s suppresses output and reports via exit code
# @description: Runs bzcmp -s on identical and differing compressed inputs and verifies stdout/stderr stay empty while the exit code carries the result.
# @timeout: 180
# @tags: usage, bzcmp, silent
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'identical payload alpha\nbeta\ngamma\n' >"$tmpdir/a.txt"
cp "$tmpdir/a.txt" "$tmpdir/b.txt"
printf 'different payload\nbeta\ngamma\n' >"$tmpdir/c.txt"

bzip2 -k "$tmpdir/a.txt"
bzip2 -k "$tmpdir/b.txt"
bzip2 -k "$tmpdir/c.txt"

# Identical: exit 0, no stdout, no stderr.
status=0
bzcmp -s "$tmpdir/a.txt.bz2" "$tmpdir/b.txt.bz2" \
  >"$tmpdir/equal.out" 2>"$tmpdir/equal.err" || status=$?
[[ "$status" -eq 0 ]] || {
  printf 'expected exit 0 for identical inputs, got %s\n' "$status" >&2
  exit 1
}
[[ ! -s "$tmpdir/equal.out" ]] || { printf '-s emitted stdout for equal inputs\n' >&2; cat "$tmpdir/equal.out" >&2; exit 1; }
[[ ! -s "$tmpdir/equal.err" ]] || { printf '-s emitted stderr for equal inputs\n' >&2; cat "$tmpdir/equal.err" >&2; exit 1; }

# Different: exit 1, still no stdout, no stderr.
status=0
bzcmp -s "$tmpdir/a.txt.bz2" "$tmpdir/c.txt.bz2" \
  >"$tmpdir/diff.out" 2>"$tmpdir/diff.err" || status=$?
[[ "$status" -eq 1 ]] || {
  printf 'expected exit 1 for differing inputs, got %s\n' "$status" >&2
  exit 1
}
[[ ! -s "$tmpdir/diff.out" ]] || { printf '-s emitted stdout for differing inputs\n' >&2; cat "$tmpdir/diff.out" >&2; exit 1; }
[[ ! -s "$tmpdir/diff.err" ]] || { printf '-s emitted stderr for differing inputs\n' >&2; cat "$tmpdir/diff.err" >&2; exit 1; }
