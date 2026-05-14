#!/usr/bin/env bash
# @testcase: usage-jshon-r18-array-of-strings-second-element-unstring
# @title: jshon -e 1 -u on an array of strings yields the second element unwrapped
# @description: Pipes ["zero","one","two","three"] through jshon -e 1 -u and asserts stdout equals "one" exactly, exercising libjansson's zero-indexed array element extraction at index 1 followed by string unwrap through the -u operator.
# @timeout: 30
# @tags: usage, json, cli, array, index, unstring, r18
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

out=$(printf '["zero","one","two","three"]' | jshon -e 1 -u)
if [[ "$out" != 'one' ]]; then
  printf 'expected one, got %s\n' "$out" >&2
  exit 1
fi
