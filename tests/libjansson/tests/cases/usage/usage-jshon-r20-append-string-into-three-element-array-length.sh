#!/usr/bin/env bash
# @testcase: usage-jshon-r20-append-string-into-three-element-array-length
# @title: jshon -s value -i append on a three-element array grows length to four
# @description: Starts with the array [1,2,3], creates a JSON string "tail" with -s, inserts it at index append via -i, and asserts the resulting array has length 4, exercising libjansson's array growth via jshon's append-keyword insertion path.
# @timeout: 30
# @tags: usage, json, cli, array, append, insert, r20
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

out=$(printf '[1,2,3]' | jshon -s tail -i append -l)
[[ "$out" == "4" ]] || { printf 'expected length 4, got %s\n' "$out" >&2; exit 1; }
