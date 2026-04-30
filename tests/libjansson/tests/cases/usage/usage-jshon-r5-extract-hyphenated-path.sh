#!/usr/bin/env bash
# @testcase: usage-jshon-r5-extract-hyphenated-path
# @title: jshon -e on path with hyphenated keys
# @description: Walks a nested object whose keys contain hyphens at multiple levels and verifies that jshon -e accepts the hyphenated key tokens and returns the leaf string intact.
# @timeout: 120
# @tags: usage, json, jshon
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-r5-extract-hyphenated-path"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

json='{"top-level":{"middle-key":{"leaf-name":"hyphen-leaf-value"}}}'

printf '%s' "$json" | jshon -e top-level -e middle-key -e leaf-name -u >"$tmpdir/leaf"

if ! grep -Fxq -- 'hyphen-leaf-value' "$tmpdir/leaf"; then
  printf 'expected hyphen-leaf-value at hyphenated path, got:\n' >&2
  cat "$tmpdir/leaf" >&2
  exit 1
fi

# Leaf type must be string.
printf '%s' "$json" | jshon -e top-level -e middle-key -e leaf-name -t >"$tmpdir/type"
if ! grep -Fxq -- 'string' "$tmpdir/type"; then
  printf 'expected string type at hyphenated leaf, got:\n' >&2
  cat "$tmpdir/type" >&2
  exit 1
fi
