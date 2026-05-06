#!/usr/bin/env bash
# @testcase: usage-jshon-r10-string-with-quote-via-s-roundtrip
# @title: jshon -s preserves an embedded double quote across roundtrip
# @description: Inserts a string containing an embedded double quote via jshon -s into an object key, then extracts the value with -u and verifies the original byte sequence (including the quote) is recovered without escape leakage.
# @timeout: 60
# @tags: usage, json, cli
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

raw='left"right'
printf '{}' | jshon -s "$raw" -i message >"$tmpdir/built.json"

# Stored form must be the JSON-escaped variant containing \" .
validator_assert_contains "$tmpdir/built.json" '"message": "left\"right"'

jshon -F "$tmpdir/built.json" -e message -u >"$tmpdir/raw"
actual=$(<"$tmpdir/raw")
if [[ "$actual" != "$raw" ]]; then
  printf 'roundtrip mismatch, expected %q, got %q\n' "$raw" "$actual" >&2
  exit 1
fi
