#!/usr/bin/env bash
# @testcase: usage-jshon-r16-unstring-escaped-quote-payload
# @title: jshon -u unstrings a JSON string containing an escaped double quote
# @description: Pipes the JSON string "a\"b" (one ASCII a, one literal double quote, one ASCII b) through jshon -u and asserts stdout equals the three-character raw value a"b, exercising libjansson's JSON string unescape decoder.
# @timeout: 30
# @tags: usage, json, cli, unstring, escape
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

out=$(printf '%s' '"a\"b"' | jshon -u)
expected='a"b'
[[ "$out" == "$expected" ]] || {
  printf 'expected %s, got %s\n' "$expected" "$out" >&2
  exit 1
}
