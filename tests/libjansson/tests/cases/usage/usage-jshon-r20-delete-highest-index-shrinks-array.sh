#!/usr/bin/env bash
# @testcase: usage-jshon-r20-delete-highest-index-shrinks-array
# @title: jshon -d 3 on a four-element array reduces its length to three
# @description: Pipes [10,20,30,40] through jshon -d 3 -l and asserts the resulting length is 3, exercising libjansson's array length tracking when jshon deletes the highest-indexed element by explicit numeric index distinct from earlier rounds' coverage of front-index deletion.
# @timeout: 30
# @tags: usage, json, cli, array, delete, index, r20
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

out=$(printf '[10,20,30,40]' | jshon -d 3 -l)
[[ "$out" == "3" ]] || { printf 'expected length 3, got %s\n' "$out" >&2; exit 1; }
