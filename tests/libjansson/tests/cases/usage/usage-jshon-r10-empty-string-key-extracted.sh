#!/usr/bin/env bash
# @testcase: usage-jshon-r10-empty-string-key-extracted
# @title: jshon -e accepts the empty string as an object key
# @description: Reads an object whose sole key is the empty string, extracts the value with jshon -e "" -u, and verifies the value is recovered intact.
# @timeout: 60
# @tags: usage, json, cli
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf '{"":"empty-key-value","other":123}' | jshon -e '' -u >"$tmpdir/value"

actual=$(<"$tmpdir/value")
if [[ "$actual" != "empty-key-value" ]]; then
  printf 'expected empty-key-value, got: %q\n' "$actual" >&2
  exit 1
fi

# Sanity: the other key is still readable from the same input.
printf '{"":"empty-key-value","other":123}' | jshon -e other -u >"$tmpdir/other"
validator_assert_contains "$tmpdir/other" '123'
