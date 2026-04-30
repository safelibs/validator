#!/usr/bin/env bash
# @testcase: usage-jshon-r4-float-pi-type-number
# @title: jshon -t on fractional literal reports number
# @description: Wraps a fractional literal in an array (jshon rejects bare scalar roots), extracts it, and verifies jshon reports the type as number and -u round-trips the exact value unchanged. Uses 0.25, which is exactly representable in IEEE 754 binary64 so jshon's printf does not widen it to a long decimal expansion.
# @timeout: 120
# @tags: usage, json, jshon
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-r4-float-pi-type-number"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# 0.25 is exact in binary64; jshon -u will not surface a long expansion.
json='[0.25]'

printf '%s' "$json" | jshon -e 0 -t >"$tmpdir/type"
if ! grep -Fxq -- 'number' "$tmpdir/type"; then
  printf 'expected number type for 0.25, got:\n' >&2
  cat "$tmpdir/type" >&2
  exit 1
fi

printf '%s' "$json" | jshon -e 0 -u >"$tmpdir/val"
if ! grep -Eq '^0\.25(0+)?$' "$tmpdir/val"; then
  printf 'expected unstringed 0.25, got:\n' >&2
  cat "$tmpdir/val" >&2
  exit 1
fi
