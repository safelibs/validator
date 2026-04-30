#!/usr/bin/env bash
# @testcase: usage-jshon-r6-large-array-500-length
# @title: jshon -l counts a 500-element array
# @description: Builds a JSON array of 500 sequential integers (0..499), writes it to a file, and verifies jshon -F reports length 500, type array, and that boundary indices 0, 250, and 499 each unstring to their numeric value. Stress test extending the round-3 200-element baseline.
# @timeout: 180
# @tags: usage, json, jshon
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-r6-large-array-500-length"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Construct [0,1,2,...,499] deterministically.
{
  printf '['
  sep=''
  for ((i = 0; i < 500; i++)); do
    printf '%s%d' "$sep" "$i"
    sep=','
  done
  printf ']'
} >"$tmpdir/big.json"

# Type is array.
jshon -F "$tmpdir/big.json" -t >"$tmpdir/type"
if ! grep -Fxq -- 'array' "$tmpdir/type"; then
  printf 'expected array type, got:\n' >&2
  cat "$tmpdir/type" >&2
  exit 1
fi

# Length is exactly 500.
jshon -F "$tmpdir/big.json" -l >"$tmpdir/len"
if ! grep -Fxq -- '500' "$tmpdir/len"; then
  printf 'expected length 500, got:\n' >&2
  cat "$tmpdir/len" >&2
  exit 1
fi

# Boundary lookups: first, mid, and last index.
jshon -F "$tmpdir/big.json" -e 0 -u >"$tmpdir/v0"
if ! grep -Fxq -- '0' "$tmpdir/v0"; then
  printf 'expected 0 at index 0, got:\n' >&2
  cat "$tmpdir/v0" >&2
  exit 1
fi

jshon -F "$tmpdir/big.json" -e 250 -u >"$tmpdir/v250"
if ! grep -Fxq -- '250' "$tmpdir/v250"; then
  printf 'expected 250 at index 250, got:\n' >&2
  cat "$tmpdir/v250" >&2
  exit 1
fi

jshon -F "$tmpdir/big.json" -e 499 -u >"$tmpdir/v499"
if ! grep -Fxq -- '499' "$tmpdir/v499"; then
  printf 'expected 499 at index 499, got:\n' >&2
  cat "$tmpdir/v499" >&2
  exit 1
fi

# Type at a representative index is number.
jshon -F "$tmpdir/big.json" -e 250 -t >"$tmpdir/t250"
if ! grep -Fxq -- 'number' "$tmpdir/t250"; then
  printf 'expected number type at index 250, got:\n' >&2
  cat "$tmpdir/t250" >&2
  exit 1
fi
