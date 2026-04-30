#!/usr/bin/env bash
# @testcase: usage-jshon-large-integer-preserved
# @title: jshon preserves a large integer
# @description: Reads a 15-digit integer member and verifies the digits round-trip through jshon -u without truncation.
# @timeout: 120
# @tags: usage, json
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-large-integer-preserved"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# 15-digit integer, well within signed 64-bit range used by jansson.
big='123456789012345'
printf '{"big":%s}' "$big" >"$tmpdir/input.json"

jshon -F "$tmpdir/input.json" -e big -u >"$tmpdir/out"

if ! grep -Fxq -- "$big" "$tmpdir/out"; then
  printf 'expected %s, got:\n' "$big" >&2
  cat "$tmpdir/out" >&2
  exit 1
fi

# Type must still be number after the round-trip.
jshon -F "$tmpdir/input.json" -e big -t >"$tmpdir/type"
validator_assert_contains "$tmpdir/type" 'number'
