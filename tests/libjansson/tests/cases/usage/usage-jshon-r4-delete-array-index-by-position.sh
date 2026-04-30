#!/usr/bin/env bash
# @testcase: usage-jshon-r4-delete-array-index-by-position
# @title: jshon -d removes an array element by position
# @description: Deletes the middle element of [10,20,30,40] with jshon -d 1 and verifies the resulting array has length 3, that index 1 now holds the value previously at index 2, and that the deleted value 20 no longer appears at any surviving index.
# @timeout: 120
# @tags: usage, json, jshon
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-r4-delete-array-index-by-position"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

json='[10,20,30,40]'

# Delete index 1 (value 20) and emit the array.
printf '%s' "$json" | jshon -d 1 >"$tmpdir/arr.json"

# Length must drop from 4 to 3.
jshon -F "$tmpdir/arr.json" -l >"$tmpdir/len"
if ! grep -Fxq -- '3' "$tmpdir/len"; then
  printf 'expected length 3 after delete, got:\n' >&2
  cat "$tmpdir/len" >&2
  exit 1
fi

# Index 0 stays 10, index 1 shifts to 30, index 2 to 40.
declare -A expected=([0]=10 [1]=30 [2]=40)
for idx in 0 1 2; do
  jshon -F "$tmpdir/arr.json" -e "$idx" -u >"$tmpdir/v_$idx"
  if ! grep -Fxq -- "${expected[$idx]}" "$tmpdir/v_$idx"; then
    printf 'expected index %s == %s, got:\n' "$idx" "${expected[$idx]}" >&2
    cat "$tmpdir/v_$idx" >&2
    exit 1
  fi
done

# The deleted value 20 must not appear at any surviving index.
for idx in 0 1 2; do
  if grep -Fxq -- '20' "$tmpdir/v_$idx"; then
    printf 'unexpected deleted value 20 at index %s\n' "$idx" >&2
    exit 1
  fi
done
