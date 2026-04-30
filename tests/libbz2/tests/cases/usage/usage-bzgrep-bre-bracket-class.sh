#!/usr/bin/env bash
# @testcase: usage-bzgrep-bre-bracket-class
# @title: bzgrep POSIX BRE bracket class
# @description: Searches a compressed file with a default POSIX BRE pattern using a bracket class and verifies only matching lines are emitted.
# @timeout: 180
# @tags: usage, bzip2, search
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzgrep-bre-bracket-class"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Mix of digit-prefixed and letter-prefixed lines plus a non-match.
printf '1-one\n2-two\nthree\n4-four\nzz\n' >"$tmpdir/in.txt"
bzip2 -c "$tmpdir/in.txt" >"$tmpdir/in.txt.bz2"

# BRE: lines that begin with a single digit followed by a dash.
bzgrep '^[0-9]-' "$tmpdir/in.txt.bz2" >"$tmpdir/out"

# Three digit-prefixed lines must match; the two non-digit lines must not.
match_count=$(wc -l <"$tmpdir/out")
[[ "$match_count" -eq 3 ]] || {
  printf 'expected 3 matches, got %s\n' "$match_count" >&2
  cat "$tmpdir/out" >&2
  exit 1
}
grep -Fxq '1-one' "$tmpdir/out"
grep -Fxq '2-two' "$tmpdir/out"
grep -Fxq '4-four' "$tmpdir/out"
if grep -Fxq 'three' "$tmpdir/out"; then
  printf 'non-digit line "three" leaked into matches\n' >&2
  exit 1
fi
if grep -Fxq 'zz' "$tmpdir/out"; then
  printf 'non-digit line "zz" leaked into matches\n' >&2
  exit 1
fi
