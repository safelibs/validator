#!/usr/bin/env bash
# @testcase: usage-jshon-r17-two-level-extract-via-parent-keys
# @title: jshon -e parent -e child two-level navigation yields child string
# @description: Pipes an object {"parent":{"child":"leaf"}} through jshon -e parent -e child -u and asserts stdout is exactly "leaf", exercising libjansson's two-step object navigation with distinct key names from the r16 a/b test.
# @timeout: 30
# @tags: usage, json, cli, extract, nested
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

out=$(printf '{"parent":{"child":"leaf"}}' | jshon -e parent -e child -u)
if [[ "$out" != 'leaf' ]]; then
  printf 'expected leaf, got %s\n' "$out" >&2
  exit 1
fi
