#!/usr/bin/env bash
# @testcase: usage-jshon-r17-type-object-root
# @title: jshon -t on an empty object root reports type "object"
# @description: Pipes the two-character empty-object literal {} through jshon -t and asserts stdout equals "object" exactly, exercising libjansson's empty-object type reflection through the documented -t operator at the root.
# @timeout: 30
# @tags: usage, json, cli, type, object-root
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

type=$(printf '{}' | jshon -t)
if [[ "$type" != 'object' ]]; then
  printf 'expected object, got %s\n' "$type" >&2
  exit 1
fi
