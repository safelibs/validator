#!/usr/bin/env bash
# @testcase: usage-jshon-insert-array-back
# @title: jshon insert at array back
# @description: Appends a new value to the end of a three-element array by inserting at the post-last index and verifies the inserted value lands at the new tail.
# @timeout: 120
# @tags: usage, json
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-insert-array-back"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

json='[10,20,30]'

# jshon's -i accepts the literal string 'append' for arrays. The previously
# pushed integer (-n 99) is removed from the stack and pushed onto the
# array tail.
result=$(printf '%s' "$json" | jshon -n '99' -i append)
printf '%s' "$result" >"$tmpdir/result.json"

# Length must now be 4.
jshon -F "$tmpdir/result.json" -l >"$tmpdir/len"
grep -Fxq -- '4' "$tmpdir/len" || {
  printf 'expected length 4 after append, got:\n' >&2
  cat "$tmpdir/len" >&2
  exit 1
}

# Index 3 must be 99.
jshon -F "$tmpdir/result.json" -e 3 -u >"$tmpdir/last"
grep -Fxq -- '99' "$tmpdir/last" || {
  printf 'expected 99 at index 3, got:\n' >&2
  cat "$tmpdir/last" >&2
  exit 1
}

# Original head element unchanged.
jshon -F "$tmpdir/result.json" -e 0 -u >"$tmpdir/head"
grep -Fxq -- '10' "$tmpdir/head" || {
  printf 'expected 10 at index 0 still, got:\n' >&2
  cat "$tmpdir/head" >&2
  exit 1
}

# Pre-tail element unchanged.
jshon -F "$tmpdir/result.json" -e 2 -u >"$tmpdir/pre"
grep -Fxq -- '30' "$tmpdir/pre" || {
  printf 'expected 30 at index 2 still, got:\n' >&2
  cat "$tmpdir/pre" >&2
  exit 1
}
