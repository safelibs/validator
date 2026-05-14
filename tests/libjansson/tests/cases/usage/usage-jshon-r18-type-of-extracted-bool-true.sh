#!/usr/bin/env bash
# @testcase: usage-jshon-r18-type-of-extracted-bool-true
# @title: jshon -e key -t on an object whose value is true reports type "bool"
# @description: Pipes {"flag":true} through jshon -e flag -t and asserts stdout equals "bool" exactly, exercising libjansson's boolean-typed value extraction and type reflection (jshon reports the JSON true literal as type bool, distinct from null/number/string).
# @timeout: 30
# @tags: usage, json, cli, type, bool, r18
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

type=$(printf '{"flag":true}' | jshon -e flag -t)
if [[ "$type" != 'bool' ]]; then
  printf 'expected bool, got %s\n' "$type" >&2
  exit 1
fi
