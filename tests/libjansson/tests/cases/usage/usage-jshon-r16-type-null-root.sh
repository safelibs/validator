#!/usr/bin/env bash
# @testcase: usage-jshon-r16-type-null-root
# @title: jshon -t reports "null" for a JSON null root document
# @description: Pipes the literal "null" through jshon -t and asserts the reported type is exactly "null", exercising libjansson's null-type classification at the root document position.
# @timeout: 30
# @tags: usage, json, cli, type, null
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

out=$(printf 'null' | jshon -t)
[[ "$out" == "null" ]] || {
  printf 'expected null, got %s\n' "$out" >&2
  exit 1
}
