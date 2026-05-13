#!/usr/bin/env bash
# @testcase: usage-jshon-r16-length-of-three-key-object
# @title: jshon -l reports 3 for an object with three keys
# @description: Pipes an object with three top-level keys through jshon -l and asserts the printed length is exactly "3", exercising libjansson's object length reflection (number of immediate keys) through the documented -l operator.
# @timeout: 30
# @tags: usage, json, cli, length, object
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

out=$(printf '{"a":1,"b":2,"c":3}' | jshon -l)
[[ "$out" == "3" ]] || {
  printf 'expected 3, got %s\n' "$out" >&2
  exit 1
}
