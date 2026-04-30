#!/usr/bin/env bash
# @testcase: usage-jshon-r5-empty-string-length
# @title: jshon -l on empty string value
# @description: Extracts an empty string field and queries jshon -l on it, verifying that the reported byte length is exactly 0.
# @timeout: 120
# @tags: usage, json, jshon
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-r5-empty-string-length"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

json='{"label":""}'

printf '%s' "$json" | jshon -e label -l >"$tmpdir/len"

if ! grep -Fxq -- '0' "$tmpdir/len"; then
  printf 'expected length 0 for empty string, got:\n' >&2
  cat "$tmpdir/len" >&2
  exit 1
fi

# Type at the empty value must still be string.
printf '%s' "$json" | jshon -e label -t >"$tmpdir/type"
if ! grep -Fxq -- 'string' "$tmpdir/type"; then
  printf 'expected string type for empty string field, got:\n' >&2
  cat "$tmpdir/type" >&2
  exit 1
fi
