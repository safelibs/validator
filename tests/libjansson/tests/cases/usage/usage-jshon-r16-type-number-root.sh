#!/usr/bin/env bash
# @testcase: usage-jshon-r16-type-number-root
# @title: jshon -t reports "number" for a JSON integer root document
# @description: Pipes the literal "42" through jshon -t and asserts the reported type is exactly "number", exercising libjansson's number-type classification at the root document position for an integer literal.
# @timeout: 30
# @tags: usage, json, cli, type, number
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

out=$(printf '42' | jshon -t)
[[ "$out" == "number" ]] || {
  printf 'expected number, got %s\n' "$out" >&2
  exit 1
}
