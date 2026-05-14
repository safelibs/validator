#!/usr/bin/env bash
# @testcase: usage-jshon-r18-insert-number-into-object-via-n
# @title: jshon -n number -i count inserts a JSON number and extracts it as type number
# @description: Starts with empty object {}, inserts the JSON number 1337 under key "count" via jshon -n 1337 -i count, then runs -e count -t and asserts stdout equals "number" exactly, exercising libjansson's numeric insert-into-object path and the type round-trip distinct from -s string coverage.
# @timeout: 30
# @tags: usage, json, cli, insert, number, type, r18
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mod=$(printf '{}' | jshon -n 1337 -i count)
type=$(printf '%s' "$mod" | jshon -e count -t)
if [[ "$type" != 'number' ]]; then
  printf 'expected number, got %s\n' "$type" >&2
  exit 1
fi
value=$(printf '%s' "$mod" | jshon -e count -u)
if [[ "$value" != '1337' ]]; then
  printf 'expected 1337, got %s\n' "$value" >&2
  exit 1
fi
