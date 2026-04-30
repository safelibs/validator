#!/usr/bin/env bash
# @testcase: usage-jshon-r3-mixed-scalar-array-types
# @title: jshon -t reports the right type for each element of a mixed-type array
# @description: Loads an array whose elements span string, number, true, false, and null, then asserts jshon -t at each index returns the type label that matches the underlying JSON scalar.
# @timeout: 120
# @tags: usage, json, jshon
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-r3-mixed-scalar-array-types"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

json='["hello",42,true,false,null]'
printf '%s' "$json" >"$tmpdir/input.json"

# Length 5.
jshon -F "$tmpdir/input.json" -l >"$tmpdir/len"
grep -Fxq -- '5' "$tmpdir/len" || {
  printf 'expected length 5, got:\n' >&2
  cat "$tmpdir/len" >&2
  exit 1
}

probe_type() {
  local idx=$1
  local expected=$2
  jshon -F "$tmpdir/input.json" -e "$idx" -t >"$tmpdir/t-$idx"
  if ! grep -Fxq -- "$expected" "$tmpdir/t-$idx"; then
    printf 'expected type %s at index %s, got:\n' "$expected" "$idx" >&2
    cat "$tmpdir/t-$idx" >&2
    exit 1
  fi
}

probe_type 0 string
probe_type 1 number
probe_type 2 bool
probe_type 3 bool
probe_type 4 null

# String element unstrings to its raw value.
jshon -F "$tmpdir/input.json" -e 0 -u >"$tmpdir/v0"
grep -Fxq -- 'hello' "$tmpdir/v0" || {
  printf 'expected hello at index 0, got:\n' >&2
  cat "$tmpdir/v0" >&2
  exit 1
}

# Number element unstrings to bare digits.
jshon -F "$tmpdir/input.json" -e 1 -u >"$tmpdir/v1"
grep -Fxq -- '42' "$tmpdir/v1" || {
  printf 'expected 42 at index 1, got:\n' >&2
  cat "$tmpdir/v1" >&2
  exit 1
}
