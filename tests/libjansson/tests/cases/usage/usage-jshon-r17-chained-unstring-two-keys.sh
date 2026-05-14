#!/usr/bin/env bash
# @testcase: usage-jshon-r17-chained-unstring-two-keys
# @title: jshon -e a -e b -u extracts deep string from two-level object
# @description: Pipes {"k1":{"k2":"final"}} through jshon -e k1 -e k2 -u and asserts the unwrapped stdout equals "final" exactly, exercising libjansson's chained extract-then-unstring with explicit key names k1/k2 (distinct from r16 a/b and r17 parent/child variants).
# @timeout: 30
# @tags: usage, json, cli, chain, unstring
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

out=$(printf '{"k1":{"k2":"final"}}' | jshon -e k1 -e k2 -u)
if [[ "$out" != 'final' ]]; then
  printf 'expected final, got %s\n' "$out" >&2
  exit 1
fi
