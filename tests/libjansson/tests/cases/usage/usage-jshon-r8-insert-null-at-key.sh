#!/usr/bin/env bash
# @testcase: usage-jshon-r8-insert-null-at-key
# @title: jshon -n null -i key inserts the literal null into an object
# @description: Starts from an empty object via jshon -n object, pushes a null with -n null, inserts it at key marker, and verifies the resulting document has length one, lists key marker on a -k pass, reports type null at that key on a -t pass, and that the long-form value null is identical to its abbreviation -n n.
# @timeout: 120
# @tags: usage, json, jshon
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-r8-insert-null-at-key"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Long form: -n null
jshon -n object -n null -i marker >"$tmpdir/long.json"

jshon -F "$tmpdir/long.json" -l >"$tmpdir/len"
grep -Fxq -- '1' "$tmpdir/len" || {
  printf 'expected length 1 after inserting null, got:\n' >&2
  cat "$tmpdir/len" >&2
  exit 1
}

jshon -F "$tmpdir/long.json" -k >"$tmpdir/keys"
grep -Fxq -- 'marker' "$tmpdir/keys" || {
  printf 'expected key marker, got:\n' >&2
  cat "$tmpdir/keys" >&2
  exit 1
}

jshon -F "$tmpdir/long.json" -e marker -t >"$tmpdir/type"
grep -Fxq -- 'null' "$tmpdir/type" || {
  printf 'expected null type at marker, got:\n' >&2
  cat "$tmpdir/type" >&2
  exit 1
}

# Abbreviated form: -n n must produce the same document.
jshon -n object -n n -i marker >"$tmpdir/short.json"

if ! diff -u "$tmpdir/long.json" "$tmpdir/short.json" >"$tmpdir/diff"; then
  printf 'expected -n null and -n n to produce identical output:\n' >&2
  cat "$tmpdir/diff" >&2
  exit 1
fi
