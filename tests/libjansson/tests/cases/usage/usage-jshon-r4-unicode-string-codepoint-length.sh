#!/usr/bin/env bash
# @testcase: usage-jshon-r4-unicode-string-codepoint-length
# @title: jshon -l on unicode string reports UTF-8 byte length
# @description: Stores a three-codepoint string containing an escaped e-acute ("a\\u00e9z", whose UTF-8 encoding is 4 bytes), verifies jshon -l reports 4 (jshon's documented "length" for strings is the strlen of the UTF-8 representation, not a codepoint count), and that -u emits exactly the 4 UTF-8 bytes followed by a newline.
# @timeout: 120
# @tags: usage, json, jshon, unicode
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-r4-unicode-string-codepoint-length"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Three codepoints: 'a', U+00E9 (e-acute), 'z'. UTF-8 encoding is 4 bytes.
printf '{"s":"a\\u00e9z"}' >"$tmpdir/input.json"

# jshon -l on a string returns the UTF-8 byte length (the C strlen) on
# Ubuntu 24.04's jansson 2.14 / jshon 20131105, not a codepoint count.
jshon -F "$tmpdir/input.json" -e s -l >"$tmpdir/len"
if ! grep -Fxq -- '4' "$tmpdir/len"; then
  printf 'expected UTF-8 byte length 4, got:\n' >&2
  cat "$tmpdir/len" >&2
  exit 1
fi

# Sanity: the unstringed value really is 4 UTF-8 bytes.
jshon -F "$tmpdir/input.json" -e s -u >"$tmpdir/raw"
# Strip jshon's trailing newline before counting.
bytes=$(wc -c <"$tmpdir/raw")
if [[ "$bytes" -ne 5 ]]; then
  # 4 content bytes + 1 trailing newline from jshon -u.
  printf 'expected 5 bytes (4 content + newline), got %s:\n' "$bytes" >&2
  od -c "$tmpdir/raw" >&2
  exit 1
fi
