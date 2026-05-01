#!/usr/bin/env bash
# @testcase: usage-jshon-r7-keys-count-via-wc
# @title: jshon -k line count matches -l for a 50-key object
# @description: Generates a 50-entry JSON object on the fly via shell, lists its keys with jshon -k piped to wc -l, asks jshon -l for the length on the same input, and verifies the two independent counts agree at exactly 50.
# @timeout: 120
# @tags: usage, json, jshon
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-r7-keys-count-via-wc"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Build a 50-key object: {"k0":0,"k1":1,...,"k49":49}.
{
  printf '{'
  for i in $(seq 0 49); do
    if [[ $i -gt 0 ]]; then printf ','; fi
    printf '"k%s":%s' "$i" "$i"
  done
  printf '}'
} >"$tmpdir/big.json"

# -k count via wc.
keys_count=$(jshon -F "$tmpdir/big.json" -k | wc -l)
if [[ "$keys_count" -ne 50 ]]; then
  printf 'expected 50 keys, got %s\n' "$keys_count" >&2
  exit 1
fi

# -l independent length.
jshon -F "$tmpdir/big.json" -l >"$tmpdir/len"
if ! grep -Fxq -- '50' "$tmpdir/len"; then
  printf 'expected length 50, got:\n' >&2
  cat "$tmpdir/len" >&2
  exit 1
fi

# Spot-check a middle and tail key.
jshon -F "$tmpdir/big.json" -e k25 -u >"$tmpdir/v25"
grep -Fxq -- '25' "$tmpdir/v25" || {
  printf 'expected 25 at k25, got:\n' >&2
  cat "$tmpdir/v25" >&2
  exit 1
}
jshon -F "$tmpdir/big.json" -e k49 -u >"$tmpdir/v49"
grep -Fxq -- '49' "$tmpdir/v49" || {
  printf 'expected 49 at k49, got:\n' >&2
  cat "$tmpdir/v49" >&2
  exit 1
}
