#!/usr/bin/env bash
# @testcase: usage-jshon-r9-string-with-quote-escaped
# @title: jshon -u preserves embedded double quote
# @description: Extracts a string field whose value contains an escaped double quote and verifies the rendered output keeps the literal quote character.
# @timeout: 60
# @tags: usage, json, string
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# JSON-escaped backslash-quote in the string value.
json='{"msg":"she said \"hi\""}'
printf '%s' "$json" | jshon -e msg -u >"$tmpdir/out"
got=$(cat "$tmpdir/out")
expected='she said "hi"'
[[ "$got" == "$expected" ]] || {
  printf 'expected %s, got %s\n' "$expected" "$got" >&2
  exit 1
}
