#!/usr/bin/env bash
# @testcase: usage-jshon-r17-type-array-root-from-jshon-n
# @title: jshon -n array -t reports array type for a freshly constructed empty array
# @description: Constructs a brand-new empty array via jshon -n array, pipes it back into jshon -t, and asserts stdout equals "array" exactly, exercising libjansson's empty-array construction and type reflection through the documented -n array idiom.
# @timeout: 30
# @tags: usage, json, cli, type, array-root
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

arr=$(jshon -n array)
type=$(printf '%s' "$arr" | jshon -t)
if [[ "$type" != 'array' ]]; then
  printf 'expected array, got %s\n' "$type" >&2
  exit 1
fi
