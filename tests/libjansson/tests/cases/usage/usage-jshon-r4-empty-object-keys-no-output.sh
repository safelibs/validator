#!/usr/bin/env bash
# @testcase: usage-jshon-r4-empty-object-keys-no-output
# @title: jshon -k on empty object yields no lines
# @description: Runs jshon -k against {} and verifies the output has zero lines, distinguishing the empty-keys case from the empty-string-line case.
# @timeout: 120
# @tags: usage, json, jshon
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-r4-empty-object-keys-no-output"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf '%s' '{}' | jshon -k >"$tmpdir/keys"

count=$(wc -l <"$tmpdir/keys")
if [[ "$count" -ne 0 ]]; then
  printf 'expected 0 key lines for empty object, got %s:\n' "$count" >&2
  cat "$tmpdir/keys" >&2
  exit 1
fi

# File must also be byte-empty (no trailing newline either).
size=$(wc -c <"$tmpdir/keys")
if [[ "$size" -ne 0 ]]; then
  printf 'expected empty bytes for empty object keys, got %s bytes:\n' "$size" >&2
  od -c "$tmpdir/keys" >&2
  exit 1
fi
