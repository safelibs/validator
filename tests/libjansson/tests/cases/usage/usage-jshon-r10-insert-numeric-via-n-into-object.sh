#!/usr/bin/env bash
# @testcase: usage-jshon-r10-insert-numeric-via-n-into-object
# @title: jshon -n 42 -i adds a numeric key to an existing object
# @description: Inserts the literal integer 42 with -n 42 -i count into an existing one-key object and verifies the new key is typed as number, the original key remains, and the unstrung value parses back to 42.
# @timeout: 60
# @tags: usage, json, cli
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf '{"label":"things"}' | jshon -n 42 -i count >"$tmpdir/built.json"

jshon -F "$tmpdir/built.json" -l >"$tmpdir/length"
length=$(<"$tmpdir/length")
if [[ "$length" != "2" ]]; then
  printf 'expected length 2 after inserting count, got: %q\n' "$length" >&2
  cat "$tmpdir/built.json" >&2
  exit 1
fi

jshon -F "$tmpdir/built.json" -e count -t >"$tmpdir/type"
validator_assert_contains "$tmpdir/type" 'number'

jshon -F "$tmpdir/built.json" -e count -u >"$tmpdir/value"
value=$(<"$tmpdir/value")
if [[ "$value" != "42" ]]; then
  printf 'expected count=42, got: %q\n' "$value" >&2
  exit 1
fi

jshon -F "$tmpdir/built.json" -e label -u >"$tmpdir/label"
validator_assert_contains "$tmpdir/label" 'things'
