#!/usr/bin/env bash
# @testcase: usage-jshon-r19-length-of-eleven-element-array
# @title: jshon -l on an eleven-element integer array reports 11
# @description: Pipes [0,1,2,3,4,5,6,7,8,9,10] through jshon -l and asserts stdout equals "11" exactly, exercising libjansson's array-length reporting at a length distinct from earlier r17/r18 fixtures and across a single-digit-to-two-digit transition.
# @timeout: 30
# @tags: usage, json, cli, array, length, eleven, r19
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

out=$(printf '[0,1,2,3,4,5,6,7,8,9,10]' | jshon -l)
if [[ "$out" != '11' ]]; then
  printf 'expected 11, got %s\n' "$out" >&2
  exit 1
fi
