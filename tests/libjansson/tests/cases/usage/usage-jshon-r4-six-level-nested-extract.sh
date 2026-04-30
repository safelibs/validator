#!/usr/bin/env bash
# @testcase: usage-jshon-r4-six-level-nested-extract
# @title: jshon -e walks six levels of nesting
# @description: Builds a six-level deep object l1.l2.l3.l4.l5.l6 == "deepest" and verifies jshon -t reports object at every intermediate level, string at the leaf, and -u returns the leaf string verbatim.
# @timeout: 120
# @tags: usage, json, jshon
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-r4-six-level-nested-extract"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

json='{"l1":{"l2":{"l3":{"l4":{"l5":{"l6":"deepest"}}}}}}'
printf '%s' "$json" >"$tmpdir/input.json"

# All intermediate levels must be objects.
for path in \
  "" \
  "-e l1" \
  "-e l1 -e l2" \
  "-e l1 -e l2 -e l3" \
  "-e l1 -e l2 -e l3 -e l4" \
  "-e l1 -e l2 -e l3 -e l4 -e l5"
do
  # shellcheck disable=SC2086
  jshon -F "$tmpdir/input.json" $path -t >"$tmpdir/t"
  if ! grep -Fxq -- 'object' "$tmpdir/t"; then
    printf 'expected object at path "%s", got:\n' "$path" >&2
    cat "$tmpdir/t" >&2
    exit 1
  fi
done

# Leaf must be a string.
jshon -F "$tmpdir/input.json" -e l1 -e l2 -e l3 -e l4 -e l5 -e l6 -t \
  >"$tmpdir/leaf_t"
if ! grep -Fxq -- 'string' "$tmpdir/leaf_t"; then
  printf 'expected string at l6, got:\n' >&2
  cat "$tmpdir/leaf_t" >&2
  exit 1
fi

jshon -F "$tmpdir/input.json" -e l1 -e l2 -e l3 -e l4 -e l5 -e l6 -u \
  >"$tmpdir/leaf"
if ! grep -Fxq -- 'deepest' "$tmpdir/leaf"; then
  printf 'expected leaf "deepest", got:\n' >&2
  cat "$tmpdir/leaf" >&2
  exit 1
fi
