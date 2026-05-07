#!/usr/bin/env bash
# @testcase: usage-jshon-r13-insert-array-into-object-creates-nested-array
# @title: jshon -n '[1,2,3]' -i nums inserts a literal array under a new key
# @description: Starts from the empty object and inserts a literal three-element array via -n '[1,2,3]' -i nums, then verifies -e nums -t reports array, -e nums -l reports length 3, and -e nums -e 0 -u recovers the first element.
# @timeout: 30
# @tags: usage, json, cli, insert
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

result=$(printf '{}' | jshon -n '[1,2,3]' -i nums)
typ=$(printf '%s' "$result" | jshon -e nums -t)
[[ "$typ" == "array" ]] || { printf 'expected array, got %s\n' "$typ" >&2; exit 1; }
len=$(printf '%s' "$result" | jshon -e nums -l)
[[ "$len" == "3" ]] || { printf 'expected 3, got %s\n' "$len" >&2; exit 1; }
first=$(printf '%s' "$result" | jshon -e nums -e 0 -u)
[[ "$first" == "1" ]] || { printf 'expected 1, got %s\n' "$first" >&2; exit 1; }
