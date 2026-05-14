#!/usr/bin/env bash
# @testcase: usage-jshon-r18-array-extract-negative-one-last
# @title: jshon -e -1 -u on a four-element string array yields the last element
# @description: Pipes ["alpha","beta","gamma","delta"] through jshon -e -1 -u and asserts stdout equals "delta" exactly, exercising libjansson's negative-index-from-end semantics in jshon's -e operator with a distinct fixture from r11 negative-one coverage.
# @timeout: 30
# @tags: usage, json, cli, array, negative-index, r18
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

out=$(printf '["alpha","beta","gamma","delta"]' | jshon -e -1 -u)
if [[ "$out" != 'delta' ]]; then
  printf 'expected delta, got %s\n' "$out" >&2
  exit 1
fi
