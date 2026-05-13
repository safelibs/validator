#!/usr/bin/env bash
# @testcase: usage-jshon-r16-extract-nested-two-levels-unstring
# @title: jshon -e a -e b -u extracts a two-level nested string value
# @description: Pipes a small object {"a":{"b":"deep"}} through jshon -e a -e b -u and asserts the printed value is exactly "deep" with no surrounding quotes, exercising libjansson's nested object navigation through two -e steps followed by -u (unstring).
# @timeout: 30
# @tags: usage, json, cli, nested, extract
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

out=$(printf '{"a":{"b":"deep"}}' | jshon -e a -e b -u)
[[ "$out" == "deep" ]] || {
  printf 'expected deep, got %s\n' "$out" >&2
  exit 1
}
