#!/usr/bin/env bash
# @testcase: usage-jshon-r15-append-numeric-via-n-into-array-end
# @title: jshon -n 99 -i append adds a number to the end of an existing array
# @description: Pipes a 3-element numeric array through jshon -n 99 -i append and verifies the resulting array has length four with the literal 99 at the last position, exercising the documented append insertion mode for arrays via the -i append keyword.
# @timeout: 30
# @tags: usage, json, cli, insert, array
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

result=$(printf '[1,2,3]' | jshon -n 99 -i append)
len=$(printf '%s' "$result" | jshon -l)
[[ "$len" == "4" ]] || { printf 'expected length 4, got %s\n' "$len" >&2; exit 1; }
last=$(printf '%s' "$result" | jshon -e 3 -u)
[[ "$last" == "99" ]] || { printf 'expected last 99, got %s\n' "$last" >&2; exit 1; }
first=$(printf '%s' "$result" | jshon -e 0 -u)
[[ "$first" == "1" ]] || { printf 'expected first 1, got %s\n' "$first" >&2; exit 1; }
