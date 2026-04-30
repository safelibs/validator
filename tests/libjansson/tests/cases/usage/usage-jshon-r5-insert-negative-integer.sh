#!/usr/bin/env bash
# @testcase: usage-jshon-r5-insert-negative-integer
# @title: jshon insert negative integer at array front
# @description: Builds a fresh negative integer with jshon -n -1 and inserts it at index 0 of an existing array, verifying length grows by one, the new front element reads back as -1, and the previous head shifts to index 1.
# @timeout: 120
# @tags: usage, json, jshon
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-r5-insert-negative-integer"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

json='[100,200,300]'

# Insert -1 at the front of the array.
result=$(printf '%s' "$json" | jshon -n -1 -i 0)
printf '%s' "$result" >"$tmpdir/result.json"

# Length is now 4.
jshon -F "$tmpdir/result.json" -l >"$tmpdir/len"
if ! grep -Fxq -- '4' "$tmpdir/len"; then
  printf 'expected length 4 after negative-int insert, got:\n' >&2
  cat "$tmpdir/len" >&2
  exit 1
fi

# Index 0 reads back as -1.
jshon -F "$tmpdir/result.json" -e 0 -u >"$tmpdir/idx0"
if ! grep -Fxq -- '-1' "$tmpdir/idx0"; then
  printf 'expected -1 at index 0, got:\n' >&2
  cat "$tmpdir/idx0" >&2
  exit 1
fi

# Type at index 0 is number.
jshon -F "$tmpdir/result.json" -e 0 -t >"$tmpdir/type0"
if ! grep -Fxq -- 'number' "$tmpdir/type0"; then
  printf 'expected number type at index 0, got:\n' >&2
  cat "$tmpdir/type0" >&2
  exit 1
fi

# The original head (100) shifted to index 1.
jshon -F "$tmpdir/result.json" -e 1 -u >"$tmpdir/idx1"
if ! grep -Fxq -- '100' "$tmpdir/idx1"; then
  printf 'expected 100 at index 1 after front insert, got:\n' >&2
  cat "$tmpdir/idx1" >&2
  exit 1
fi
