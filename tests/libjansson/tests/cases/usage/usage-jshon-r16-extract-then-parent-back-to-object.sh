#!/usr/bin/env bash
# @testcase: usage-jshon-r16-extract-then-parent-back-to-object
# @title: jshon -e then -p restores parent object and reports type "object"
# @description: Pipes an object {"k":"v"} into jshon -e k -p -t and asserts stdout equals "object", exercising the documented parent navigation: extract a leaf then -p pops back to the original object whose type is "object".
# @timeout: 30
# @tags: usage, json, cli, parent
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

out=$(printf '{"k":"v"}' | jshon -e k -p -t)
[[ "$out" == "object" ]] || {
  printf 'expected object after -p, got %s\n' "$out" >&2
  exit 1
}
