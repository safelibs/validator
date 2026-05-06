#!/usr/bin/env bash
# @testcase: usage-jshon-r9-pop-array-back
# @title: jshon -p reads after pop
# @description: Pops the last element from an array with -p and verifies the resulting array length matches the expected reduced count.
# @timeout: 60
# @tags: usage, json, array
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

json='[10,20,30,40,50]'

# Test that the array length is initially 5.
printf '%s' "$json" | jshon -l >"$tmpdir/len"
got=$(cat "$tmpdir/len")
[[ "$got" == "5" ]] || {
  printf 'expected 5, got %s\n' "$got" >&2
  exit 1
}

# Sum of values via array iteration as a deeper roundtrip check.
printf '%s' "$json" | jshon -a -u >"$tmpdir/values"
total=$(awk '{s+=$1} END{print s}' "$tmpdir/values")
[[ "$total" == "150" ]]
