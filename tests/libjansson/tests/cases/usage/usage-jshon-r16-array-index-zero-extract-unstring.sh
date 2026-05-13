#!/usr/bin/env bash
# @testcase: usage-jshon-r16-array-index-zero-extract-unstring
# @title: jshon -e 0 -u extracts the first element of a string array
# @description: Pipes a three-element string array through jshon -e 0 -u and asserts stdout equals "first" exactly, exercising libjansson's array-by-integer-index lookup followed by JSON-string unescape.
# @timeout: 30
# @tags: usage, json, cli, array, index
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

out=$(printf '["first","second","third"]' | jshon -e 0 -u)
[[ "$out" == "first" ]] || {
  printf 'expected first, got %s\n' "$out" >&2
  exit 1
}
