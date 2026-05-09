#!/usr/bin/env bash
# @testcase: usage-jshon-r13-insert-array-into-object-creates-nested-array
# @title: jshon -n [] then -a inserts arrays by chained operations under a new key
# @description: Starts from the empty object, inserts an empty array under key "nums" with -n [] -i nums, then navigates back to nums and appends 1, 2, 3 via three -n N -a -p chains, finally verifies -e nums -t reports array, -e nums -l reports length 3, and -e nums -e 0 -u recovers the first element. (Noble's jshon rejects -n '[1,2,3]' as a literal stack value; arrays must be built with -a one element at a time.)
# @timeout: 30
# @tags: usage, json, cli, insert
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

result=$(printf '{}' \
  | jshon -n [] -i nums \
          -e nums -n 1 -a -p \
          -e nums -n 2 -a -p \
          -e nums -n 3 -a -p)
typ=$(printf '%s' "$result" | jshon -e nums -t)
[[ "$typ" == "array" ]] || { printf 'expected array, got %s\n' "$typ" >&2; exit 1; }
len=$(printf '%s' "$result" | jshon -e nums -l)
[[ "$len" == "3" ]] || { printf 'expected 3, got %s\n' "$len" >&2; exit 1; }
first=$(printf '%s' "$result" | jshon -e nums -e 0 -u)
[[ "$first" == "1" ]] || { printf 'expected 1, got %s\n' "$first" >&2; exit 1; }
