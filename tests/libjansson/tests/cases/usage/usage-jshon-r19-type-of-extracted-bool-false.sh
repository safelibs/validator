#!/usr/bin/env bash
# @testcase: usage-jshon-r19-type-of-extracted-bool-false
# @title: jshon -e flag -t on {"flag":false} returns bool
# @description: Pipes {"flag":false} through jshon -e flag -t and asserts stdout equals "bool" exactly, exercising libjansson's type classification of the JSON false literal extracted from an object (distinct from the r18 true-value coverage).
# @timeout: 30
# @tags: usage, json, cli, type, bool, false, r19
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

out=$(printf '{"flag":false}' | jshon -e flag -t)
if [[ "$out" != 'bool' ]]; then
  printf 'expected bool, got %s\n' "$out" >&2
  exit 1
fi
