#!/usr/bin/env bash
# @testcase: usage-jshon-r19-delete-second-array-element-length
# @title: jshon -d 1 on a four-element array reduces -l to 3
# @description: Pipes ["a","b","c","d"] through jshon -d 1 followed by -l and asserts the captured length equals "3" (libjansson removes index 1 and the array becomes ["a","c","d"]), exercising libjansson's array-element deletion path through jshon's -d on a numeric index.
# @timeout: 30
# @tags: usage, json, cli, delete, array-index, length, r19
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

out=$(printf '["a","b","c","d"]' | jshon -d 1 -l)
if [[ "$out" != '3' ]]; then
  printf 'expected length 3, got %s\n' "$out" >&2
  exit 1
fi
