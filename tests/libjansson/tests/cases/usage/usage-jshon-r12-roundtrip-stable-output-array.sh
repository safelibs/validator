#!/usr/bin/env bash
# @testcase: usage-jshon-r12-roundtrip-stable-output-array
# @title: jshon round-trips a simple integer array unchanged through stdin
# @description: Feeds a canonical [1,2,3] integer array through jshon with no actions and verifies the output is equivalent JSON whose -l length is 3 and whose first element is 1.
# @timeout: 30
# @tags: usage, json, cli, roundtrip
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

result=$(printf '[1,2,3]' | jshon)
len=$(printf '%s' "$result" | jshon -l)
[[ "$len" == "3" ]] || { printf 'expected 3, got %s\n' "$len" >&2; exit 1; }
first=$(printf '%s' "$result" | jshon -e 0 -u)
[[ "$first" == "1" ]] || { printf 'expected 1, got %s\n' "$first" >&2; exit 1; }
