#!/usr/bin/env bash
# @testcase: usage-jshon-r5-string-with-bracket-content
# @title: jshon -e on string containing JSON-like brackets
# @description: Reads a string value whose contents look like a JSON array literal ("[hello]") and verifies that jshon -e -u returns the raw bracketed string verbatim instead of attempting to parse it as a sub-document.
# @timeout: 120
# @tags: usage, json, jshon
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-r5-string-with-bracket-content"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

json='{"payload":"[hello]"}'

# Type must be string, not array.
printf '%s' "$json" | jshon -e payload -t >"$tmpdir/type"
if ! grep -Fxq -- 'string' "$tmpdir/type"; then
  printf 'expected string type for bracket-content payload, got:\n' >&2
  cat "$tmpdir/type" >&2
  exit 1
fi

# Unstringed value must be exactly "[hello]".
printf '%s' "$json" | jshon -e payload -u >"$tmpdir/value"
if ! grep -Fxq -- '[hello]' "$tmpdir/value"; then
  printf 'expected [hello] verbatim, got:\n' >&2
  cat "$tmpdir/value" >&2
  exit 1
fi

# Length is the byte length of the literal "[hello]" (7 bytes).
printf '%s' "$json" | jshon -e payload -l >"$tmpdir/len"
if ! grep -Fxq -- '7' "$tmpdir/len"; then
  printf 'expected length 7 for [hello], got:\n' >&2
  cat "$tmpdir/len" >&2
  exit 1
fi
