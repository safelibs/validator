#!/usr/bin/env bash
# @testcase: usage-jshon-r19-keys-of-five-key-object-line-count
# @title: jshon -k on a five-key object emits exactly five key-name lines
# @description: Pipes an object with five keys "one"..."five" through jshon -k, captures the output, and asserts the line count is exactly 5 and that each key name appears once, exercising libjansson's five-element object key enumeration with explicit named keys (distinct from r18 three-key coverage).
# @timeout: 30
# @tags: usage, json, cli, keys, five-keys, r19
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf '{"one":1,"two":2,"three":3,"four":4,"five":5}' | jshon -k >"$tmpdir/out"
count=$(wc -l <"$tmpdir/out")
if [[ "$count" -ne 5 ]]; then
  printf 'expected 5 keys, got %s\n' "$count" >&2
  cat "$tmpdir/out" >&2
  exit 1
fi
for key in one two three four five; do
  if ! LC_ALL=C grep -Fxq "$key" "$tmpdir/out"; then
    printf 'missing key %s\n' "$key" >&2
    cat "$tmpdir/out" >&2
    exit 1
  fi
done
