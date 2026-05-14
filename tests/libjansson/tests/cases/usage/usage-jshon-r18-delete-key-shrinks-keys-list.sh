#!/usr/bin/env bash
# @testcase: usage-jshon-r18-delete-key-shrinks-keys-list
# @title: jshon -d on a three-key object then -k reports the two surviving keys
# @description: Pipes {"a":1,"b":2,"c":3} through jshon -d b followed by -k and asserts the captured output lists exactly the two surviving keys "a" and "c" (no "b"), exercising libjansson's object-key deletion followed by key enumeration on the modified object.
# @timeout: 30
# @tags: usage, json, cli, delete, keys, r18
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf '{"a":1,"b":2,"c":3}' | jshon -d b -k >"$tmpdir/out"
count=$(wc -l <"$tmpdir/out")
if [[ "$count" -ne 2 ]]; then
  printf 'expected 2 keys after deletion, got %s\n' "$count" >&2
  cat "$tmpdir/out" >&2
  exit 1
fi
for key in a c; do
  if ! LC_ALL=C grep -Fxq "$key" "$tmpdir/out"; then
    printf 'missing surviving key %s\n' "$key" >&2
    cat "$tmpdir/out" >&2
    exit 1
  fi
done
if LC_ALL=C grep -Fxq 'b' "$tmpdir/out"; then
  echo 'deleted key b still present in keys output' >&2
  cat "$tmpdir/out" >&2
  exit 1
fi
