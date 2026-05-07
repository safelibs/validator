#!/usr/bin/env bash
# @testcase: usage-jshon-r12-delete-array-first-element
# @title: jshon -d 0 removes the first array element and shifts the rest
# @description: Pipes a 4-element string array through jshon -d 0 and verifies the result has length 3 with the original second element now at index 0.
# @timeout: 30
# @tags: usage, json, cli, delete
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

result=$(printf '["a","b","c","d"]' | jshon -d 0)
len=$(printf '%s' "$result" | jshon -l)
[[ "$len" == "3" ]] || { printf 'expected length 3, got %s\n' "$len" >&2; exit 1; }
first=$(printf '%s' "$result" | jshon -e 0 -u)
[[ "$first" == "b" ]] || { printf 'expected b, got %s\n' "$first" >&2; exit 1; }
