#!/usr/bin/env bash
# @testcase: usage-jshon-r17-length-of-empty-array-zero
# @title: jshon -l on an empty array root reports length 0
# @description: Pipes the two-character empty-array literal [] through jshon -l and asserts stdout equals "0" exactly, exercising libjansson's array length reflection for the boundary case of an empty container.
# @timeout: 30
# @tags: usage, json, cli, length, empty-array
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

len=$(printf '[]' | jshon -l)
if [[ "$len" != '0' ]]; then
  printf 'expected 0, got %s\n' "$len" >&2
  exit 1
fi
