#!/usr/bin/env bash
# @testcase: usage-jshon-r18-insert-string-into-object-then-extract
# @title: jshon -s value -i key inserts a string into an object and extracts it back
# @description: Starts with empty object {}, inserts the string "hello" under key "greet" via jshon -s hello -i greet, then re-extracts via -e greet -u and asserts the recovered value equals "hello" exactly, exercising libjansson's string insert-into-object path through the documented -s/-i chain.
# @timeout: 30
# @tags: usage, json, cli, insert, string, r18
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mod=$(printf '{}' | jshon -s hello -i greet)
out=$(printf '%s' "$mod" | jshon -e greet -u)
if [[ "$out" != 'hello' ]]; then
  printf 'expected hello, got %s\n' "$out" >&2
  exit 1
fi
