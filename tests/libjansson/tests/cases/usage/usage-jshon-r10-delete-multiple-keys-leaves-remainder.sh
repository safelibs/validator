#!/usr/bin/env bash
# @testcase: usage-jshon-r10-delete-multiple-keys-leaves-remainder
# @title: chained jshon -d removes two keys and leaves the third intact
# @description: Applies two consecutive -d operations to a three-key object and verifies the resulting object contains exactly the remaining key with its original value preserved.
# @timeout: 60
# @tags: usage, json, cli
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf '{"alpha":1,"bravo":2,"charlie":3}' | jshon -d alpha -d bravo >"$tmpdir/trimmed.json"

jshon -F "$tmpdir/trimmed.json" -l >"$tmpdir/length"
length=$(<"$tmpdir/length")
if [[ "$length" != "1" ]]; then
  printf 'expected length 1 after two deletes, got: %q\n' "$length" >&2
  cat "$tmpdir/trimmed.json" >&2
  exit 1
fi

jshon -F "$tmpdir/trimmed.json" -k >"$tmpdir/keys"
key=$(<"$tmpdir/keys")
if [[ "$key" != "charlie" ]]; then
  printf 'expected sole remaining key charlie, got: %q\n' "$key" >&2
  exit 1
fi

jshon -F "$tmpdir/trimmed.json" -e charlie -u >"$tmpdir/value"
validator_assert_contains "$tmpdir/value" '3'
