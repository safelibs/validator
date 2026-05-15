#!/usr/bin/env bash
# @testcase: usage-jshon-r19-array-of-objects-second-field-extract
# @title: jshon -e 1 -e name -u on an array of objects yields the second object's name
# @description: Pipes [{"name":"alpha"},{"name":"beta"},{"name":"gamma"}] through jshon -e 1 -e name -u and asserts stdout equals "beta" exactly, exercising libjansson's chained -e descent through an array index into an object field in a single jshon invocation.
# @timeout: 30
# @tags: usage, json, cli, array, object, chained-extract, r19
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

out=$(printf '[{"name":"alpha"},{"name":"beta"},{"name":"gamma"}]' \
  | jshon -e 1 -e name -u)
if [[ "$out" != 'beta' ]]; then
  printf 'expected beta, got %s\n' "$out" >&2
  exit 1
fi
