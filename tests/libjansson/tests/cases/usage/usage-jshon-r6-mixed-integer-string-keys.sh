#!/usr/bin/env bash
# @testcase: usage-jshon-r6-mixed-integer-string-keys
# @title: jshon -e on object with numeric-string and word-string keys
# @description: Constructs an object whose keys mix purely numeric strings ("1", "2", "10") with alphabetic words ("first", "second"), then verifies jshon -e treats every key as a string (since JSON object keys are always strings) and returns the matching values for both flavors.
# @timeout: 120
# @tags: usage, json, jshon
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-r6-mixed-integer-string-keys"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

json='{"1":"one-val","2":"two-val","10":"ten-val","first":"alpha","second":"beta"}'

# Length is exactly five regardless of key shape.
printf '%s' "$json" | jshon -l >"$tmpdir/len"
if ! grep -Fxq -- '5' "$tmpdir/len"; then
  printf 'expected length 5 for mixed-key object, got:\n' >&2
  cat "$tmpdir/len" >&2
  exit 1
fi

# Numeric-string key "1" returns its mapped value via -e (object lookup, not array index).
printf '%s' "$json" | jshon -e 1 -u >"$tmpdir/v-1"
if ! grep -Fxq -- 'one-val' "$tmpdir/v-1"; then
  printf 'expected one-val at key "1", got:\n' >&2
  cat "$tmpdir/v-1" >&2
  exit 1
fi

# Numeric-string key "10" must not collide with key "1".
printf '%s' "$json" | jshon -e 10 -u >"$tmpdir/v-10"
if ! grep -Fxq -- 'ten-val' "$tmpdir/v-10"; then
  printf 'expected ten-val at key "10", got:\n' >&2
  cat "$tmpdir/v-10" >&2
  exit 1
fi

# Alphabetic key still resolves correctly alongside numeric-string siblings.
printf '%s' "$json" | jshon -e first -u >"$tmpdir/v-first"
if ! grep -Fxq -- 'alpha' "$tmpdir/v-first"; then
  printf 'expected alpha at key "first", got:\n' >&2
  cat "$tmpdir/v-first" >&2
  exit 1
fi

# Verify the value type at a numeric-string key is reported as string.
printf '%s' "$json" | jshon -e 2 -t >"$tmpdir/t-2"
if ! grep -Fxq -- 'string' "$tmpdir/t-2"; then
  printf 'expected string type at key "2", got:\n' >&2
  cat "$tmpdir/t-2" >&2
  exit 1
fi
