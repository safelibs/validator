#!/usr/bin/env bash
# @testcase: usage-jshon-r18-type-of-extracted-null-value
# @title: jshon -e key -t on an object whose value is null reports type "null"
# @description: Pipes {"x":null} through jshon -e x -t and asserts stdout equals "null" exactly, exercising libjansson's null-typed value extraction and type reflection through chained -e/-t operators (distinct from -e key -u which would not apply to null).
# @timeout: 30
# @tags: usage, json, cli, type, null, r18
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

type=$(printf '{"x":null}' | jshon -e x -t)
if [[ "$type" != 'null' ]]; then
  printf 'expected null, got %s\n' "$type" >&2
  exit 1
fi
