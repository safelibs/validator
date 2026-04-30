#!/usr/bin/env bash
# @testcase: usage-jshon-r6-insert-null-at-index
# @title: jshon insert null at array index 1
# @description: Pushes a fresh null with jshon -n null and inserts it at index 1 of a four-element integer array, verifying that the inserted slot reports type null, the array length grows to five, and the previous index-1 element shifts right to index 2.
# @timeout: 120
# @tags: usage, json, jshon
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-r6-insert-null-at-index"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

json='[10,20,30,40]'

# Push a fresh null and insert it at index 1.
result=$(printf '%s' "$json" | jshon -n null -i 1)
printf '%s' "$result" >"$tmpdir/result.json"

# Length grows by one to five.
jshon -F "$tmpdir/result.json" -l >"$tmpdir/len"
if ! grep -Fxq -- '5' "$tmpdir/len"; then
  printf 'expected length 5 after null insert, got:\n' >&2
  cat "$tmpdir/len" >&2
  exit 1
fi

# The slot at index 1 now reports type null.
jshon -F "$tmpdir/result.json" -e 1 -t >"$tmpdir/t1"
if ! grep -Fxq -- 'null' "$tmpdir/t1"; then
  printf 'expected null type at index 1, got:\n' >&2
  cat "$tmpdir/t1" >&2
  exit 1
fi

# Index 0 unchanged.
jshon -F "$tmpdir/result.json" -e 0 -u >"$tmpdir/v0"
if ! grep -Fxq -- '10' "$tmpdir/v0"; then
  printf 'expected 10 at index 0, got:\n' >&2
  cat "$tmpdir/v0" >&2
  exit 1
fi

# Original index-1 element (20) shifted to index 2.
jshon -F "$tmpdir/result.json" -e 2 -u >"$tmpdir/v2"
if ! grep -Fxq -- '20' "$tmpdir/v2"; then
  printf 'expected 20 at index 2 after shift, got:\n' >&2
  cat "$tmpdir/v2" >&2
  exit 1
fi

# Tail value preserved at the new index 4.
jshon -F "$tmpdir/result.json" -e 4 -u >"$tmpdir/v4"
if ! grep -Fxq -- '40' "$tmpdir/v4"; then
  printf 'expected 40 at index 4 after shift, got:\n' >&2
  cat "$tmpdir/v4" >&2
  exit 1
fi
