#!/usr/bin/env bash
# @testcase: usage-jshon-r5-multiple-d-sequence
# @title: jshon multiple -d in sequence
# @description: Chains three -d deletes against the root object in a single jshon invocation and verifies that all three keys are removed while the surviving keys remain reachable.
# @timeout: 120
# @tags: usage, json, jshon
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-r5-multiple-d-sequence"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

json='{"a":1,"b":2,"c":3,"d":4,"e":5}'

# Delete a, c, and d in a single chained invocation; emit final keys.
printf '%s' "$json" | jshon -d a -d c -d d -k >"$tmpdir/keys"

# Three deletes leave two keys behind.
count=$(wc -l <"$tmpdir/keys")
if [[ "$count" -ne 2 ]]; then
  printf 'expected 2 keys after triple delete, got %s:\n' "$count" >&2
  cat "$tmpdir/keys" >&2
  exit 1
fi

for gone in a c d; do
  if grep -Fxq -- "$gone" "$tmpdir/keys"; then
    printf 'expected %s to be deleted, got keys:\n' "$gone" >&2
    cat "$tmpdir/keys" >&2
    exit 1
  fi
done

for kept in b e; do
  if ! grep -Fxq -- "$kept" "$tmpdir/keys"; then
    printf 'expected %s to remain, got keys:\n' "$kept" >&2
    cat "$tmpdir/keys" >&2
    exit 1
  fi
done
