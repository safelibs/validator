#!/usr/bin/env bash
# @testcase: usage-jshon-r6-chained-three-deletes
# @title: jshon chained -d a -d b -d c against root object
# @description: Issues three consecutive -d deletes (a, b, c) in a single jshon invocation against a six-key object, then re-emits the surviving JSON and verifies that the three named keys are gone, the remaining three keys are intact, and -l reports length 3.
# @timeout: 120
# @tags: usage, json, jshon
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-r6-chained-three-deletes"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

json='{"a":1,"b":2,"c":3,"d":4,"e":5,"f":6}'

# Chain three deletes and capture the resulting JSON.
printf '%s' "$json" | jshon -d a -d b -d c >"$tmpdir/after.json"

# After three deletes from a six-key object, three keys remain.
jshon -F "$tmpdir/after.json" -l >"$tmpdir/len"
if ! grep -Fxq -- '3' "$tmpdir/len"; then
  printf 'expected length 3 after triple-delete chain, got:\n' >&2
  cat "$tmpdir/len" >&2
  exit 1
fi

# Survivors must each resolve to their original integer value.
for pair in 'd:4' 'e:5' 'f:6'; do
  key=${pair%%:*}
  want=${pair##*:}
  jshon -F "$tmpdir/after.json" -e "$key" -u >"$tmpdir/v-$key"
  if ! grep -Fxq -- "$want" "$tmpdir/v-$key"; then
    printf 'expected %s at surviving key %s, got:\n' "$want" "$key" >&2
    cat "$tmpdir/v-$key" >&2
    exit 1
  fi
done

# Deleted keys must not appear in the -k listing.
jshon -F "$tmpdir/after.json" -k >"$tmpdir/keys"
for gone in a b c; do
  if grep -Fxq -- "$gone" "$tmpdir/keys"; then
    printf 'expected %s deleted, got keys:\n' "$gone" >&2
    cat "$tmpdir/keys" >&2
    exit 1
  fi
done
