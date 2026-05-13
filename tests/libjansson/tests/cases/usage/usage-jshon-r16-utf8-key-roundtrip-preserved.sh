#!/usr/bin/env bash
# @testcase: usage-jshon-r16-utf8-key-roundtrip-preserved
# @title: jshon round-trips an object whose key contains a UTF-8 snowman
# @description: Pipes an object whose key is the UTF-8 snowman U+2603 through jshon (no operators) and asserts the round-tripped output contains both the snowman byte sequence and the string value, exercising libjansson's UTF-8 preservation for object keys.
# @timeout: 30
# @tags: usage, json, cli, utf8, key
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Snowman U+2603 in UTF-8 bytes: e2 98 83
input=$'{"\xe2\x98\x83":"snow"}'
out=$(printf '%s' "$input" | jshon)

LC_ALL=C printf '%s' "$out" | grep -qP $'\xe2\x98\x83' || {
  echo 'expected snowman bytes in output' >&2
  printf '%s' "$out" | od -An -c | head -3 >&2
  exit 1
}
validator_make_fixture "$tmpdir/out" "$out"
validator_assert_contains "$tmpdir/out" "snow"
