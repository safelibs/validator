#!/usr/bin/env bash
# @testcase: usage-jshon-r4-integer-zero-type-number
# @title: jshon -t on integer 0 reports number
# @description: Wraps integer 0 in a single-element array, descends with -e 0 -t, and verifies jshon classifies 0 as number while -u emits the literal 0.
# @timeout: 120
# @tags: usage, json, jshon
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-r4-integer-zero-type-number"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

json='[0]'

printf '%s' "$json" | jshon -e 0 -t >"$tmpdir/type"
if ! grep -Fxq -- 'number' "$tmpdir/type"; then
  printf 'expected number type for integer 0, got:\n' >&2
  cat "$tmpdir/type" >&2
  exit 1
fi

printf '%s' "$json" | jshon -e 0 -u >"$tmpdir/val"
if ! grep -Fxq -- '0' "$tmpdir/val"; then
  printf 'expected unstringed 0, got:\n' >&2
  cat "$tmpdir/val" >&2
  exit 1
fi

# And the array length must be 1.
printf '%s' "$json" | jshon -l >"$tmpdir/len"
if ! grep -Fxq -- '1' "$tmpdir/len"; then
  printf 'expected array length 1, got:\n' >&2
  cat "$tmpdir/len" >&2
  exit 1
fi
