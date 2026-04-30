#!/usr/bin/env bash
# @testcase: usage-jshon-big-object-100-keys
# @title: jshon enumerates a 100-key object
# @description: Builds a JSON object with exactly 100 keys, then verifies jshon -l reports 100 and jshon -k emits 100 distinct key lines that match the constructed names.
# @timeout: 180
# @tags: usage, json
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-big-object-100-keys"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Build {"k000":0,"k001":1,...,"k099":99} deterministically.
{
  printf '{'
  sep=''
  for ((i = 0; i < 100; i++)); do
    printf '%s"k%03d":%d' "$sep" "$i" "$i"
    sep=','
  done
  printf '}'
} >"$tmpdir/big.json"

# Length must be 100.
jshon -F "$tmpdir/big.json" -l >"$tmpdir/len"
if ! grep -Fxq -- '100' "$tmpdir/len"; then
  printf 'expected length 100, got:\n' >&2
  cat "$tmpdir/len" >&2
  exit 1
fi

# Key listing must produce exactly 100 lines.
jshon -F "$tmpdir/big.json" -k >"$tmpdir/keys"
count=$(wc -l <"$tmpdir/keys")
if [[ "$count" -ne 100 ]]; then
  printf 'expected 100 key lines, got %s\n' "$count" >&2
  exit 1
fi

# Spot-check a handful of keys are present.
for k in k000 k007 k042 k099; do
  if ! grep -Fxq -- "$k" "$tmpdir/keys"; then
    printf 'expected key %s in jshon -k output\n' "$k" >&2
    exit 1
  fi
done

# Spot-check a value lookup at a specific key.
jshon -F "$tmpdir/big.json" -e k042 -u >"$tmpdir/v42"
if ! grep -Fxq -- '42' "$tmpdir/v42"; then
  printf 'expected value 42 at k042, got:\n' >&2
  cat "$tmpdir/v42" >&2
  exit 1
fi
