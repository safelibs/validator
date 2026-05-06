#!/usr/bin/env bash
# @testcase: usage-jshon-r9-array-extract-then-length
# @title: jshon -e then -l reports nested array length
# @description: Extracts a nested array via -e and pipes through -l to verify the inner length matches the inserted element count.
# @timeout: 60
# @tags: usage, json, array
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

json='{"data":{"items":[1,2,3,4,5,6,7]}}'

printf '%s' "$json" | jshon -e data -e items -l >"$tmpdir/out"
got=$(cat "$tmpdir/out")
[[ "$got" == "7" ]] || {
  printf 'expected 7, got %s\n' "$got" >&2
  exit 1
}
