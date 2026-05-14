#!/usr/bin/env bash
# @testcase: usage-jshon-r17-keys-of-two-key-object
# @title: jshon -k on a two-key object emits both key names
# @description: Pipes an object with exactly two keys "alpha" and "omega" through jshon -k and asserts the captured output contains both key names on separate lines (alpha and omega), exercising libjansson's object key enumeration with a small explicit-key fixture.
# @timeout: 30
# @tags: usage, json, cli, keys, object
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf '{"alpha":1,"omega":2}' | jshon -k >"$tmpdir/out"
LC_ALL=C grep -Fxq 'alpha' "$tmpdir/out" || {
  echo 'missing alpha key' >&2
  cat "$tmpdir/out" >&2
  exit 1
}
LC_ALL=C grep -Fxq 'omega' "$tmpdir/out" || {
  echo 'missing omega key' >&2
  cat "$tmpdir/out" >&2
  exit 1
}
count=$(wc -l <"$tmpdir/out")
if [[ "$count" -ne 2 ]]; then
  printf 'expected 2 keys, got %s\n' "$count" >&2
  cat "$tmpdir/out" >&2
  exit 1
fi
