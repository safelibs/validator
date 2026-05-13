#!/usr/bin/env bash
# @testcase: usage-jshon-r16-string-wrap-text-into-json-string
# @title: jshon -s wraps a raw text payload into a quoted JSON string literal
# @description: Pipes the empty input through jshon -s hello-r16 and asserts stdout is exactly the seven-character payload wrapped in JSON double quotes ("hello-r16"), exercising libjansson's string-serialiser invoked through the documented -s wrap operator.
# @timeout: 30
# @tags: usage, json, cli, string-wrap
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

out=$(jshon -s hello-r16 </dev/null)
expected='"hello-r16"'
[[ "$out" == "$expected" ]] || {
  printf 'expected %s, got %s\n' "$expected" "$out" >&2
  exit 1
}
