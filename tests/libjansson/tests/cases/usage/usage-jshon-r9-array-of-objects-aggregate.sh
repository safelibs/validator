#!/usr/bin/env bash
# @testcase: usage-jshon-r9-array-of-objects-aggregate
# @title: jshon array of objects aggregate -a -e
# @description: Iterates an array of objects with -a -e to extract one field per object and verifies each extracted value appears in the output.
# @timeout: 60
# @tags: usage, json, array
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

json='[{"name":"alice","age":30},{"name":"bob","age":25},{"name":"carol","age":40}]'

printf '%s' "$json" | jshon -a -e name -u >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'alice'
validator_assert_contains "$tmpdir/out" 'bob'
validator_assert_contains "$tmpdir/out" 'carol'

n=$(wc -l <"$tmpdir/out")
[[ "$n" == "3" ]] || {
  printf 'expected 3 lines, got %s\n' "$n" >&2
  exit 1
}
