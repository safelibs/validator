#!/usr/bin/env bash
# @testcase: usage-jshon-r6-insert-true-at-index
# @title: jshon insert true at array index 2
# @description: Pushes a fresh boolean true with jshon -n true and inserts it at index 2 of a four-element string array, verifying that -t at index 2 reports bool, the array length grows to five, and the previous index-2 string shifts right to index 3.
# @timeout: 120
# @tags: usage, json, jshon
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-r6-insert-true-at-index"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

json='["a","b","c","d"]'

# Push a fresh true keyword and insert it at index 2.
result=$(printf '%s' "$json" | jshon -n true -i 2)
printf '%s' "$result" >"$tmpdir/result.json"

# Length grows by one.
jshon -F "$tmpdir/result.json" -l >"$tmpdir/len"
if ! grep -Fxq -- '5' "$tmpdir/len"; then
  printf 'expected length 5 after true insert, got:\n' >&2
  cat "$tmpdir/len" >&2
  exit 1
fi

# Slot at index 2 reports bool type.
jshon -F "$tmpdir/result.json" -e 2 -t >"$tmpdir/t2"
if ! grep -Fxq -- 'bool' "$tmpdir/t2"; then
  printf 'expected bool type at index 2, got:\n' >&2
  cat "$tmpdir/t2" >&2
  exit 1
fi

# Slot at index 2 unstrings to the literal "true".
jshon -F "$tmpdir/result.json" -e 2 -u >"$tmpdir/v2"
if ! grep -Fxq -- 'true' "$tmpdir/v2"; then
  printf 'expected true at index 2, got:\n' >&2
  cat "$tmpdir/v2" >&2
  exit 1
fi

# Original head and pre-insert prefix unchanged.
jshon -F "$tmpdir/result.json" -e 0 -u >"$tmpdir/v0"
if ! grep -Fxq -- 'a' "$tmpdir/v0"; then
  printf 'expected a at index 0, got:\n' >&2
  cat "$tmpdir/v0" >&2
  exit 1
fi

jshon -F "$tmpdir/result.json" -e 1 -u >"$tmpdir/v1"
if ! grep -Fxq -- 'b' "$tmpdir/v1"; then
  printf 'expected b at index 1, got:\n' >&2
  cat "$tmpdir/v1" >&2
  exit 1
fi

# The previous index-2 element ("c") now sits at index 3.
jshon -F "$tmpdir/result.json" -e 3 -u >"$tmpdir/v3"
if ! grep -Fxq -- 'c' "$tmpdir/v3"; then
  printf 'expected c at index 3 after shift, got:\n' >&2
  cat "$tmpdir/v3" >&2
  exit 1
fi
