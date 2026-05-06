#!/usr/bin/env bash
# @testcase: usage-jshon-r10-insert-string-builds-object-key
# @title: jshon -s value -i key adds a string entry to an empty object
# @description: Starts from an empty object, chains -s with -i to insert a string-valued key, and confirms the result is an object containing exactly that key with the expected unstrung value.
# @timeout: 60
# @tags: usage, json, cli
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf '{}' | jshon -s 'world' -i greeting >"$tmpdir/built.json"

jshon -F "$tmpdir/built.json" -t >"$tmpdir/type"
validator_assert_contains "$tmpdir/type" 'object'

jshon -F "$tmpdir/built.json" -k >"$tmpdir/keys"
key=$(<"$tmpdir/keys")
if [[ "$key" != "greeting" ]]; then
  printf 'expected sole key greeting, got: %q\n' "$key" >&2
  exit 1
fi

jshon -F "$tmpdir/built.json" -e greeting -u >"$tmpdir/value"
value=$(<"$tmpdir/value")
if [[ "$value" != "world" ]]; then
  printf 'expected greeting=world, got: %q\n' "$value" >&2
  exit 1
fi
