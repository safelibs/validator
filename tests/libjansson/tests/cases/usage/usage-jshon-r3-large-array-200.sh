#!/usr/bin/env bash
# @testcase: usage-jshon-r3-large-array-200
# @title: jshon -l counts a 200-element array
# @description: Constructs a JSON array containing exactly 200 integers and verifies jshon -l reports 200, jshon -e at the boundary indices returns the expected values, and jshon -t reports array.
# @timeout: 180
# @tags: usage, json, jshon
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-r3-large-array-200"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Build [0,1,2,...,199] deterministically without yes|head.
{
  printf '['
  sep=''
  for ((i = 0; i < 200; i++)); do
    printf '%s%d' "$sep" "$i"
    sep=','
  done
  printf ']'
} >"$tmpdir/big.json"

# Type must be array.
jshon -F "$tmpdir/big.json" -t >"$tmpdir/type"
grep -Fxq -- 'array' "$tmpdir/type" || {
  printf 'expected array type, got:\n' >&2
  cat "$tmpdir/type" >&2
  exit 1
}

# Length must be 200.
jshon -F "$tmpdir/big.json" -l >"$tmpdir/len"
grep -Fxq -- '200' "$tmpdir/len" || {
  printf 'expected length 200, got:\n' >&2
  cat "$tmpdir/len" >&2
  exit 1
}

# Boundary lookups: index 0, index 199, and a middle index.
jshon -F "$tmpdir/big.json" -e 0 -u >"$tmpdir/v0"
grep -Fxq -- '0' "$tmpdir/v0" || {
  printf 'expected 0 at index 0, got:\n' >&2
  cat "$tmpdir/v0" >&2
  exit 1
}

jshon -F "$tmpdir/big.json" -e 199 -u >"$tmpdir/v199"
grep -Fxq -- '199' "$tmpdir/v199" || {
  printf 'expected 199 at index 199, got:\n' >&2
  cat "$tmpdir/v199" >&2
  exit 1
}

jshon -F "$tmpdir/big.json" -e 100 -u >"$tmpdir/v100"
grep -Fxq -- '100' "$tmpdir/v100" || {
  printf 'expected 100 at index 100, got:\n' >&2
  cat "$tmpdir/v100" >&2
  exit 1
}
