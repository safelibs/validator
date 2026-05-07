#!/usr/bin/env bash
# @testcase: usage-jshon-r14-array-extract-then-length-of-nested
# @title: jshon -e 1 -l after array extract reports nested array length
# @description: Pipes an array containing a nested 4-element array as its second element through jshon -e 1 -l and verifies the reported length is exactly 4, exercising chained extract followed by length on nested array context.
# @timeout: 30
# @tags: usage, json, cli, length
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

len=$(printf '[1,[10,20,30,40],3]' | jshon -e 1 -l)
[[ "$len" == "4" ]] || { printf 'expected 4, got %s\n' "$len" >&2; exit 1; }
