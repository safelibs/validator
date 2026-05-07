#!/usr/bin/env bash
# @testcase: usage-jshon-r12-insert-into-array-at-zero
# @title: jshon -i 0 inserts a string at the front of an array
# @description: Pipes a string through -s and inserts it into an array at position 0 with -i 0; verifies the resulting array starts with the inserted element and the original elements shift right.
# @timeout: 30
# @tags: usage, json, cli, insert
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

result=$(printf '["b","c"]' | jshon -s "a" -i 0)
first=$(printf '%s' "$result" | jshon -e 0 -u)
[[ "$first" == "a" ]] || { printf 'expected a, got %s\n' "$first" >&2; exit 1; }
len=$(printf '%s' "$result" | jshon -l)
[[ "$len" == "3" ]] || { printf 'expected 3, got %s\n' "$len" >&2; exit 1; }
