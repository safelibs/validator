#!/usr/bin/env bash
# @testcase: usage-jshon-r3-five-level-nested-extract
# @title: jshon -e walks five levels of nesting
# @description: Builds a JSON document nested five object levels deep and verifies jshon -e returns the matching subtree at every level, with the leaf -u producing the final string and intermediate -t reporting object at each level.
# @timeout: 120
# @tags: usage, json, jshon
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-r3-five-level-nested-extract"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Five-level nesting: l1.l2.l3.l4.l5 == "bottom"
json='{"l1":{"l2":{"l3":{"l4":{"l5":"bottom"}}}}}'
printf '%s' "$json" >"$tmpdir/input.json"

# At each intermediate level, type must be object.
jshon -F "$tmpdir/input.json" -t >"$tmpdir/t-root"
grep -Fxq -- 'object' "$tmpdir/t-root" || exit 1

jshon -F "$tmpdir/input.json" -e l1 -t >"$tmpdir/t-l1"
grep -Fxq -- 'object' "$tmpdir/t-l1" || {
  printf 'expected object at l1, got:\n' >&2; cat "$tmpdir/t-l1" >&2; exit 1; }

jshon -F "$tmpdir/input.json" -e l1 -e l2 -t >"$tmpdir/t-l2"
grep -Fxq -- 'object' "$tmpdir/t-l2" || {
  printf 'expected object at l1.l2, got:\n' >&2; cat "$tmpdir/t-l2" >&2; exit 1; }

jshon -F "$tmpdir/input.json" -e l1 -e l2 -e l3 -t >"$tmpdir/t-l3"
grep -Fxq -- 'object' "$tmpdir/t-l3" || {
  printf 'expected object at l1.l2.l3, got:\n' >&2; cat "$tmpdir/t-l3" >&2; exit 1; }

jshon -F "$tmpdir/input.json" -e l1 -e l2 -e l3 -e l4 -t >"$tmpdir/t-l4"
grep -Fxq -- 'object' "$tmpdir/t-l4" || {
  printf 'expected object at l1.l2.l3.l4, got:\n' >&2; cat "$tmpdir/t-l4" >&2; exit 1; }

# Leaf is a string.
jshon -F "$tmpdir/input.json" -e l1 -e l2 -e l3 -e l4 -e l5 -t >"$tmpdir/t-l5"
grep -Fxq -- 'string' "$tmpdir/t-l5" || {
  printf 'expected string at l5, got:\n' >&2; cat "$tmpdir/t-l5" >&2; exit 1; }

# Unstring the leaf and check the value.
jshon -F "$tmpdir/input.json" -e l1 -e l2 -e l3 -e l4 -e l5 -u >"$tmpdir/leaf"
if ! grep -Fxq -- 'bottom' "$tmpdir/leaf"; then
  printf 'expected leaf bottom, got:\n' >&2
  cat "$tmpdir/leaf" >&2
  exit 1
fi
