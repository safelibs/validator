#!/usr/bin/env bash
# @testcase: usage-jshon-r13-delete-shrinks-array-length
# @title: jshon -d 1 reduces a 5-element array to length 4
# @description: Pipes a 5-element integer array through jshon -d 1 and verifies the resulting -l length is exactly 4 and the original element previously at index 2 has shifted to index 1.
# @timeout: 30
# @tags: usage, json, cli, delete
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

result=$(printf '[10,20,30,40,50]' | jshon -d 1)
len=$(printf '%s' "$result" | jshon -l)
[[ "$len" == "4" ]] || { printf 'expected 4, got %s\n' "$len" >&2; exit 1; }
shifted=$(printf '%s' "$result" | jshon -e 1 -u)
[[ "$shifted" == "30" ]] || { printf 'expected 30 at index 1, got %s\n' "$shifted" >&2; exit 1; }
