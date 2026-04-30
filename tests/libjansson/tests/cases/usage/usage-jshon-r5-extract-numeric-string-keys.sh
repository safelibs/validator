#!/usr/bin/env bash
# @testcase: usage-jshon-r5-extract-numeric-string-keys
# @title: jshon -e on object with numeric-looking string keys
# @description: Confirms that jshon -e treats numeric-looking object keys "0" and "1" as ordinary string keys (object lookup) rather than as array indices, and that the associated values resolve correctly.
# @timeout: 120
# @tags: usage, json, jshon
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-r5-extract-numeric-string-keys"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

json='{"0":"zero-value","1":"one-value","2":"two-value"}'

# Root must be reported as object, not array.
printf '%s' "$json" | jshon -t >"$tmpdir/roottype"
if ! grep -Fxq -- 'object' "$tmpdir/roottype"; then
  printf 'expected root type object, got:\n' >&2
  cat "$tmpdir/roottype" >&2
  exit 1
fi

printf '%s' "$json" | jshon -e 0 -u >"$tmpdir/k0"
if ! grep -Fxq -- 'zero-value' "$tmpdir/k0"; then
  printf 'expected zero-value at key "0", got:\n' >&2
  cat "$tmpdir/k0" >&2
  exit 1
fi

printf '%s' "$json" | jshon -e 1 -u >"$tmpdir/k1"
if ! grep -Fxq -- 'one-value' "$tmpdir/k1"; then
  printf 'expected one-value at key "1", got:\n' >&2
  cat "$tmpdir/k1" >&2
  exit 1
fi

# All three keys must be present.
printf '%s' "$json" | jshon -k >"$tmpdir/keys"
for key in 0 1 2; do
  if ! grep -Fxq -- "$key" "$tmpdir/keys"; then
    printf 'expected key %s in keys listing, got:\n' "$key" >&2
    cat "$tmpdir/keys" >&2
    exit 1
  fi
done
