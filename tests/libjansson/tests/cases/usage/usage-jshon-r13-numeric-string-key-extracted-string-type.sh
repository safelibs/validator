#!/usr/bin/env bash
# @testcase: usage-jshon-r13-numeric-string-key-extracted-string-type
# @title: jshon -e 123 on object with numeric-string key returns the string value
# @description: Reads an object whose key is the numeric-looking string "123" and verifies jshon -e 123 -t reports the value type as string and -u prints the literal value, exercising key lookup by digit-only token in object context.
# @timeout: 30
# @tags: usage, json, cli, extract
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf '{"123":"hello"}' >"$tmpdir/in.json"
typ=$(jshon -e 123 -t <"$tmpdir/in.json")
[[ "$typ" == "string" ]] || { printf 'expected string, got %s\n' "$typ" >&2; exit 1; }
val=$(jshon -e 123 -u <"$tmpdir/in.json")
[[ "$val" == "hello" ]] || { printf 'expected hello, got %s\n' "$val" >&2; exit 1; }
