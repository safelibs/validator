#!/usr/bin/env bash
# @testcase: usage-jshon-r14-extract-array-then-pop-back-to-array
# @title: jshon -e arr -e 0 -p -l after extract-pop reports parent array length
# @description: Pipes an object containing a 4-element array under key "arr" through jshon -e arr -e 0 -p -l, popping back to the array context, and verifies the reported length is exactly 4, exercising pop after a nested extract.
# @timeout: 30
# @tags: usage, json, cli, pop
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

len=$(printf '{"arr":[10,20,30,40]}' | jshon -e arr -e 0 -p -l)
[[ "$len" == "4" ]] || { printf 'expected 4, got %s\n' "$len" >&2; exit 1; }
