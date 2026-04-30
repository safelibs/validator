#!/usr/bin/env bash
# @testcase: usage-jshon-r6-type-after-deep-delete
# @title: jshon -t after -d at a deeply nested location
# @description: Walks four levels deep into a nested object, deletes one key from the innermost object, then asks for -t at the parent, verifying the parent is still an object, its length dropped from 3 to 2, and the deleted key no longer resolves while siblings still do.
# @timeout: 120
# @tags: usage, json, jshon
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-r6-type-after-deep-delete"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Four-level nested object: l1.l2.l3.l4 has three keys.
json='{"l1":{"l2":{"l3":{"l4":{"keep":"yes","drop":"bye","also":42}}}}}'

# Delete the "drop" key inside the deepest object, then capture the inner object.
printf '%s' "$json" \
  | jshon -e l1 -e l2 -e l3 -e l4 -d drop \
  >"$tmpdir/inner.json"

# Inner object still reports object type after the deep delete.
jshon -F "$tmpdir/inner.json" -t >"$tmpdir/type"
if ! grep -Fxq -- 'object' "$tmpdir/type"; then
  printf 'expected object type after deep delete, got:\n' >&2
  cat "$tmpdir/type" >&2
  exit 1
fi

# Length is now 2 (was 3).
jshon -F "$tmpdir/inner.json" -l >"$tmpdir/len"
if ! grep -Fxq -- '2' "$tmpdir/len"; then
  printf 'expected length 2 after deep delete, got:\n' >&2
  cat "$tmpdir/len" >&2
  exit 1
fi

# Surviving keys still resolve.
jshon -F "$tmpdir/inner.json" -e keep -u >"$tmpdir/keep"
if ! grep -Fxq -- 'yes' "$tmpdir/keep"; then
  printf 'expected keep=yes survived, got:\n' >&2
  cat "$tmpdir/keep" >&2
  exit 1
fi

jshon -F "$tmpdir/inner.json" -e also -u >"$tmpdir/also"
if ! grep -Fxq -- '42' "$tmpdir/also"; then
  printf 'expected also=42 survived, got:\n' >&2
  cat "$tmpdir/also" >&2
  exit 1
fi

# Looking up the deleted key now exits non-zero.
if printf '%s' "$json" | jshon -e l1 -e l2 -e l3 -e l4 -d drop -e drop -u 2>"$tmpdir/err" >"$tmpdir/out"; then
  printf 'expected -e drop to fail after delete, but it succeeded:\n' >&2
  cat "$tmpdir/out" >&2
  exit 1
fi
