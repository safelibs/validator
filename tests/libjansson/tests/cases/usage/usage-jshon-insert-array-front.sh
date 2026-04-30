#!/usr/bin/env bash
# @testcase: usage-jshon-insert-array-front
# @title: jshon insert at array front
# @description: Inserts a new value at index 0 of a three-element array using jshon -n value -i 0 and verifies the inserted value lands at index 0 while existing elements shift right.
# @timeout: 120
# @tags: usage, json
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-insert-array-front"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

json='[10,20,30]'

# Insert 99 at the front.
result=$(printf '%s' "$json" | jshon -n '99' -i 0)
printf '%s' "$result" >"$tmpdir/result.json"

# Length must now be 4.
jshon -F "$tmpdir/result.json" -l >"$tmpdir/len"
grep -Fxq -- '4' "$tmpdir/len" || {
  printf 'expected length 4 after insert, got:\n' >&2
  cat "$tmpdir/len" >&2
  exit 1
}

# Index 0 must be 99.
jshon -F "$tmpdir/result.json" -e 0 -u >"$tmpdir/idx0"
grep -Fxq -- '99' "$tmpdir/idx0" || {
  printf 'expected 99 at index 0, got:\n' >&2
  cat "$tmpdir/idx0" >&2
  exit 1
}

# Original elements shifted right.
jshon -F "$tmpdir/result.json" -e 1 -u >"$tmpdir/idx1"
grep -Fxq -- '10' "$tmpdir/idx1" || {
  printf 'expected 10 at index 1, got:\n' >&2
  cat "$tmpdir/idx1" >&2
  exit 1
}

jshon -F "$tmpdir/result.json" -e 3 -u >"$tmpdir/idx3"
grep -Fxq -- '30' "$tmpdir/idx3" || {
  printf 'expected 30 at index 3, got:\n' >&2
  cat "$tmpdir/idx3" >&2
  exit 1
}
