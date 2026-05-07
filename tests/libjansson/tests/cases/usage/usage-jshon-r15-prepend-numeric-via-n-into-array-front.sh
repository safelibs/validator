#!/usr/bin/env bash
# @testcase: usage-jshon-r15-prepend-numeric-via-n-into-array-front
# @title: jshon -n 0 -i 0 prepends a number at index zero of an existing array
# @description: Pipes a 3-element numeric array through jshon -n 0 -i 0 and verifies the resulting array has length four with the literal 0 at index zero and the original first element shifted to index one, exercising the documented index-zero insertion mode.
# @timeout: 30
# @tags: usage, json, cli, insert, array
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

result=$(printf '[1,2,3]' | jshon -n 0 -i 0)
len=$(printf '%s' "$result" | jshon -l)
[[ "$len" == "4" ]] || { printf 'expected length 4, got %s\n' "$len" >&2; exit 1; }
first=$(printf '%s' "$result" | jshon -e 0 -u)
[[ "$first" == "0" ]] || { printf 'expected first 0, got %s\n' "$first" >&2; exit 1; }
second=$(printf '%s' "$result" | jshon -e 1 -u)
[[ "$second" == "1" ]] || { printf 'expected second 1, got %s\n' "$second" >&2; exit 1; }
