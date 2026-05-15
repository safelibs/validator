#!/usr/bin/env bash
# @testcase: usage-jshon-r19-pop-after-array-extract-yields-length
# @title: jshon -e items -e 0 -p -p -e items -l reports the original array length
# @description: Pipes {"items":[10,20,30,40,50]} through jshon -e items -e 0 -p -p -e items -l and asserts stdout equals "5" exactly, exercising libjansson's chained parent-walk (-p) after a double descent followed by re-extracting the array and asking for its length.
# @timeout: 30
# @tags: usage, json, cli, pop, parent, array, length, r19
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

out=$(printf '{"items":[10,20,30,40,50]}' \
  | jshon -e items -e 0 -p -p -e items -l)
if [[ "$out" != '5' ]]; then
  printf 'expected 5, got %s\n' "$out" >&2
  exit 1
fi
