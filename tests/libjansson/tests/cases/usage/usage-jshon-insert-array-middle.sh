#!/usr/bin/env bash
# @testcase: usage-jshon-insert-array-middle
# @title: jshon insert into array middle
# @description: Inserts a new value at index 2 of a four-element array using jshon -n value -i 2 and verifies the inserted value lands at index 2 with elements after it shifted right.
# @timeout: 120
# @tags: usage, json
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-insert-array-middle"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

json='[10,20,30,40]'

# Insert 99 at index 2 (between 20 and 30).
result=$(printf '%s' "$json" | jshon -n '99' -i 2)
printf '%s' "$result" >"$tmpdir/result.json"

# Length must now be 5.
jshon -F "$tmpdir/result.json" -l >"$tmpdir/len"
grep -Fxq -- '5' "$tmpdir/len" || {
  printf 'expected length 5 after middle insert, got:\n' >&2
  cat "$tmpdir/len" >&2
  exit 1
}

# Verify each index.
expect_at() {
  local idx=$1
  local want=$2
  jshon -F "$tmpdir/result.json" -e "$idx" -u >"$tmpdir/at$idx"
  if ! grep -Fxq -- "$want" "$tmpdir/at$idx"; then
    printf 'expected %s at index %s, got:\n' "$want" "$idx" >&2
    cat "$tmpdir/at$idx" >&2
    exit 1
  fi
}

expect_at 0 10
expect_at 1 20
expect_at 2 99
expect_at 3 30
expect_at 4 40
