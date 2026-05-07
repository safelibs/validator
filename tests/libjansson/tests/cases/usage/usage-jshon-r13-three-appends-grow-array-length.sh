#!/usr/bin/env bash
# @testcase: usage-jshon-r13-three-appends-grow-array-length
# @title: jshon -i append three times grows an array from 0 to length 3
# @description: Starts from the empty array and chains three -s value -i append pairs through jshon, verifying the resulting array has length 3 and the trailing element matches the most recent append.
# @timeout: 30
# @tags: usage, json, cli, append
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

result=$(printf '[]' | jshon -s "one" -i append -s "two" -i append -s "three" -i append)
len=$(printf '%s' "$result" | jshon -l)
[[ "$len" == "3" ]] || { printf 'expected 3, got %s\n' "$len" >&2; exit 1; }
last=$(printf '%s' "$result" | jshon -e 2 -u)
[[ "$last" == "three" ]] || { printf 'expected three, got %s\n' "$last" >&2; exit 1; }
