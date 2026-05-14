#!/usr/bin/env bash
# @testcase: usage-jshon-r18-length-of-seven-element-array
# @title: jshon -l reports 7 for a seven-element mixed array
# @description: Pipes the JSON literal [1,2,3,4,5,6,7] through jshon -l and asserts stdout equals "7" exactly, exercising libjansson's array length reflection on a longer single-line literal array than existing r17 five-element coverage.
# @timeout: 30
# @tags: usage, json, cli, length, array, r18
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

len=$(printf '[1,2,3,4,5,6,7]' | jshon -l)
if [[ "$len" != '7' ]]; then
  printf 'expected length 7, got %s\n' "$len" >&2
  exit 1
fi
