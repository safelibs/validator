#!/usr/bin/env bash
# @testcase: usage-jshon-r13-prepend-three-times-final-order
# @title: jshon prepends three values via repeated -i 0 in the expected reversed order
# @description: Starts from an empty array and prepends three string values "x" then "y" then "z" via jshon -s and -i 0 chained three times, then verifies the resulting array has length 3 and the elements appear in the order ["z","y","x"].
# @timeout: 30
# @tags: usage, json, cli, insert
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

result=$(printf '[]' | jshon -s "x" -i 0 -s "y" -i 0 -s "z" -i 0)
len=$(printf '%s' "$result" | jshon -l)
[[ "$len" == "3" ]] || { printf 'expected 3, got %s\n' "$len" >&2; exit 1; }

a0=$(printf '%s' "$result" | jshon -e 0 -u)
a1=$(printf '%s' "$result" | jshon -e 1 -u)
a2=$(printf '%s' "$result" | jshon -e 2 -u)
[[ "$a0" == "z" ]] || { printf 'expected z at 0, got %s\n' "$a0" >&2; exit 1; }
[[ "$a1" == "y" ]] || { printf 'expected y at 1, got %s\n' "$a1" >&2; exit 1; }
[[ "$a2" == "x" ]] || { printf 'expected x at 2, got %s\n' "$a2" >&2; exit 1; }
