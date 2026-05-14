#!/usr/bin/env bash
# @testcase: usage-jshon-r18-keys-of-three-key-object-line-count
# @title: jshon -k on a three-key object emits exactly three key-name lines
# @description: Pipes an object with three keys "red", "green", "blue" through jshon -k, captures the output, and asserts the line count is exactly 3 and that each key name appears once, exercising libjansson's three-element object key enumeration with explicit named keys (distinct from r17 two-key coverage).
# @timeout: 30
# @tags: usage, json, cli, keys, object, three-keys, r18
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf '{"red":1,"green":2,"blue":3}' | jshon -k >"$tmpdir/out"
count=$(wc -l <"$tmpdir/out")
if [[ "$count" -ne 3 ]]; then
  printf 'expected 3 keys, got %s\n' "$count" >&2
  cat "$tmpdir/out" >&2
  exit 1
fi
for key in red green blue; do
  if ! LC_ALL=C grep -Fxq "$key" "$tmpdir/out"; then
    printf 'missing key %s\n' "$key" >&2
    cat "$tmpdir/out" >&2
    exit 1
  fi
done
