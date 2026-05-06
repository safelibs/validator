#!/usr/bin/env bash
# @testcase: usage-jshon-r11-array-insert-append-keyword
# @title: jshon -i append adds a value to the end of an array
# @description: Starts from a 3-element array, pushes a string via -s, and inserts it with -i append; verifies the resulting array has length 4 and the new value lives at index 3.
# @timeout: 30
# @tags: usage, json, cli, append
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf '[1,2,3]' >"$tmpdir/in.json"
result=$(jshon -s "tail" -i append <"$tmpdir/in.json")

len=$(printf '%s' "$result" | jshon -l)
[[ "$len" == "4" ]] || { printf 'expected length 4, got %s\n' "$len" >&2; exit 1; }
last=$(printf '%s' "$result" | jshon -e 3 -u)
[[ "$last" == "tail" ]] || { printf 'expected tail at idx 3, got %s\n' "$last" >&2; exit 1; }
