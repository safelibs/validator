#!/usr/bin/env bash
# @testcase: usage-jshon-r7-build-object-with-s-i
# @title: jshon builds an object incrementally with -s and -i key
# @description: Starts from an empty object via jshon -n object, pushes string scalars with -s and inserts each at a named key with -i, building a three-key object whose key list, length, and per-key unstring values are all confirmed against the assembled document.
# @timeout: 120
# @tags: usage, json, jshon
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-r7-build-object-with-s-i"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Build {"name":"alpha","color":"blue","shape":"square"} from scratch.
result=$(jshon -n object \
  -s "alpha"   -i name \
  -s "blue"    -i color \
  -s "square"  -i shape)
printf '%s' "$result" >"$tmpdir/built.json"

# Length is exactly 3.
jshon -F "$tmpdir/built.json" -l >"$tmpdir/len"
grep -Fxq -- '3' "$tmpdir/len" || {
  printf 'expected length 3 on built object, got:\n' >&2
  cat "$tmpdir/len" >&2
  exit 1
}

# Keys appear (order is implementation-defined).
jshon -F "$tmpdir/built.json" -k >"$tmpdir/keys"
for k in name color shape; do
  if ! grep -Fxq -- "$k" "$tmpdir/keys"; then
    printf 'expected key %s in built object, got:\n' "$k" >&2
    cat "$tmpdir/keys" >&2
    exit 1
  fi
done

# Values round-trip via -e <key> -u.
for pair in 'name:alpha' 'color:blue' 'shape:square'; do
  k=${pair%%:*}; v=${pair##*:}
  jshon -F "$tmpdir/built.json" -e "$k" -u >"$tmpdir/v-$k"
  if ! grep -Fxq -- "$v" "$tmpdir/v-$k"; then
    printf 'expected %s at key %s, got:\n' "$v" "$k" >&2
    cat "$tmpdir/v-$k" >&2
    exit 1
  fi
done
