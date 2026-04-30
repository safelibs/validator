#!/usr/bin/env bash
# @testcase: usage-jshon-set-container-types
# @title: jshon set top-level container types
# @description: Loads a JSON object and a JSON array as the top-level value through jshon -n and confirms the type and length each match the loaded document.
# @timeout: 120
# @tags: usage, json
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-set-container-types"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# jshon -n only accepts the type-tokens 'object', 'array', 'true', 'false',
# 'null' and bare numbers (or the {}/[] short-hands). Build the populated
# object and array by feeding pre-rendered JSON into stdin; jshon parses
# stdin as the initial top-of-stack value.

# Object: type=object, length=3 keys.
printf '%s' '{"a":1,"b":2,"c":3}' | jshon -t >"$tmpdir/obj-type"
grep -Fxq -- 'object' "$tmpdir/obj-type" || {
  printf 'expected object type, got:\n' >&2
  cat "$tmpdir/obj-type" >&2
  exit 1
}

printf '%s' '{"a":1,"b":2,"c":3}' | jshon -l >"$tmpdir/obj-len"
grep -Fxq -- '3' "$tmpdir/obj-len" || {
  printf 'expected length 3, got:\n' >&2
  cat "$tmpdir/obj-len" >&2
  exit 1
}

# Array: type=array, length=4 elements.
printf '%s' '[10,20,30,40]' | jshon -t >"$tmpdir/arr-type"
grep -Fxq -- 'array' "$tmpdir/arr-type" || {
  printf 'expected array type, got:\n' >&2
  cat "$tmpdir/arr-type" >&2
  exit 1
}

printf '%s' '[10,20,30,40]' | jshon -l >"$tmpdir/arr-len"
grep -Fxq -- '4' "$tmpdir/arr-len" || {
  printf 'expected length 4, got:\n' >&2
  cat "$tmpdir/arr-len" >&2
  exit 1
}

# Empty object / empty array shapes also report correctly.
jshon -n '{}' -t >"$tmpdir/empty-obj-type"
grep -Fxq -- 'object' "$tmpdir/empty-obj-type" || {
  printf 'expected empty-object to be object, got:\n' >&2
  cat "$tmpdir/empty-obj-type" >&2
  exit 1
}

jshon -n '[]' -l >"$tmpdir/empty-arr-len"
grep -Fxq -- '0' "$tmpdir/empty-arr-len" || {
  printf 'expected empty-array length 0, got:\n' >&2
  cat "$tmpdir/empty-arr-len" >&2
  exit 1
}
