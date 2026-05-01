#!/usr/bin/env bash
# @testcase: usage-jshon-r7-nested-array-pop-length
# @title: jshon -e values -e 1 -p -l reports parent array length
# @description: Descends into a nested integer array element, pops with -p, and asks for the array length, verifying the navigator reports the size of the array (5) rather than the previously selected scalar at index 1.
# @timeout: 120
# @tags: usage, json, jshon
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-r7-nested-array-pop-length"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

json='{"values":[10,20,30,40,50]}'

# Drill into values[1], then pop back to the array, then ask for its length.
printf '%s' "$json" | jshon -e values -e 1 -p -l >"$tmpdir/len"

if ! grep -Fxq -- '5' "$tmpdir/len"; then
  printf 'expected parent array length 5 after pop, got:\n' >&2
  cat "$tmpdir/len" >&2
  exit 1
fi

# A second pop returns to the root object whose length is 1.
printf '%s' "$json" | jshon -e values -e 1 -p -p -l >"$tmpdir/rlen"
if ! grep -Fxq -- '1' "$tmpdir/rlen"; then
  printf 'expected root length 1 after two pops, got:\n' >&2
  cat "$tmpdir/rlen" >&2
  exit 1
fi
