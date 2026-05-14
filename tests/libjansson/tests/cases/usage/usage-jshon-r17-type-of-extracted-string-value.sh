#!/usr/bin/env bash
# @testcase: usage-jshon-r17-type-of-extracted-string-value
# @title: jshon -e key -t on a string-valued field reports type "string"
# @description: Pipes the object {"name":"validator"} through jshon -e name -t and asserts stdout equals "string" exactly, exercising libjansson's type reflection on an extracted scalar leaf (distinct from the r16 -p parent test).
# @timeout: 30
# @tags: usage, json, cli, type, extract
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

type=$(printf '{"name":"validator"}' | jshon -e name -t)
if [[ "$type" != 'string' ]]; then
  printf 'expected string, got %s\n' "$type" >&2
  exit 1
fi
