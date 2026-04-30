#!/usr/bin/env bash
# @testcase: usage-bzcat-three-files-args
# @title: bzcat concatenates three file arguments
# @description: Passes three independently compressed files as positional arguments to bzcat and verifies all three payloads appear in order.
# @timeout: 180
# @tags: usage, bzip2, stream
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzcat-three-files-args"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'alpha-marker\n' >"$tmpdir/a.txt"
printf 'beta-marker\n' >"$tmpdir/b.txt"
printf 'gamma-marker\n' >"$tmpdir/c.txt"
bzip2 -zk "$tmpdir/a.txt"
bzip2 -zk "$tmpdir/b.txt"
bzip2 -zk "$tmpdir/c.txt"

bzcat "$tmpdir/a.txt.bz2" "$tmpdir/b.txt.bz2" "$tmpdir/c.txt.bz2" >"$tmpdir/out"

# Output must contain all three markers and exactly three lines.
validator_assert_contains "$tmpdir/out" 'alpha-marker'
validator_assert_contains "$tmpdir/out" 'beta-marker'
validator_assert_contains "$tmpdir/out" 'gamma-marker'
line_count=$(wc -l <"$tmpdir/out")
[[ "$line_count" -eq 3 ]] || {
  printf 'expected 3 output lines, got %s\n' "$line_count" >&2
  cat "$tmpdir/out" >&2
  exit 1
}

# Order must match the argument order.
expected=$'alpha-marker\nbeta-marker\ngamma-marker'
actual=$(cat "$tmpdir/out")
[[ "$actual" == "$expected" ]] || {
  printf 'order mismatch:\n%s\n' "$actual" >&2
  exit 1
}
