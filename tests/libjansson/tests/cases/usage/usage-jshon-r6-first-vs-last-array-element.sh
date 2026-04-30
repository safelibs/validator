#!/usr/bin/env bash
# @testcase: usage-jshon-r6-first-vs-last-array-element
# @title: jshon -e on first vs last element of an array
# @description: Picks the same array's first element via -e 0 and its last element via -e <length-1>, asserting that the two extracted values are distinct, the lengths reported by -l match, and that types at both ends match expectations. Documents that positive-indexing both ends works (jshon does not support negative array indices).
# @timeout: 120
# @tags: usage, json, jshon
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-r6-first-vs-last-array-element"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

json='["alpha","bravo","charlie","delta","echo"]'

# Fetch the length, then compute last-index = length - 1 in shell.
printf '%s' "$json" | jshon -l >"$tmpdir/len"
length=$(<"$tmpdir/len")
if [[ "$length" -ne 5 ]]; then
  printf 'expected length 5, got %s\n' "$length" >&2
  exit 1
fi
last_index=$((length - 1))

# First element via index 0.
printf '%s' "$json" | jshon -e 0 -u >"$tmpdir/first"
if ! grep -Fxq -- 'alpha' "$tmpdir/first"; then
  printf 'expected alpha at index 0, got:\n' >&2
  cat "$tmpdir/first" >&2
  exit 1
fi

# Last element via the computed positive index (length-1 = 4).
printf '%s' "$json" | jshon -e "$last_index" -u >"$tmpdir/last"
if ! grep -Fxq -- 'echo' "$tmpdir/last"; then
  printf 'expected echo at index %s, got:\n' "$last_index" >&2
  cat "$tmpdir/last" >&2
  exit 1
fi

# First and last differ.
if diff -q "$tmpdir/first" "$tmpdir/last" >/dev/null; then
  printf 'expected first and last to differ, but both equal:\n' >&2
  cat "$tmpdir/first" >&2
  exit 1
fi

# Both ends report string type.
printf '%s' "$json" | jshon -e 0 -t >"$tmpdir/t-first"
printf '%s' "$json" | jshon -e "$last_index" -t >"$tmpdir/t-last"
for f in "$tmpdir/t-first" "$tmpdir/t-last"; do
  if ! grep -Fxq -- 'string' "$f"; then
    printf 'expected string type at endpoint, got %s:\n' "$f" >&2
    cat "$f" >&2
    exit 1
  fi
done

# Confirm jshon -e on the explicit positive index 0 yields the same content as
# the computed first-index path - anchors that array indexing is stable.
printf '%s' "$json" | jshon -e 0 -u >"$tmpdir/first-again"
if ! diff -q "$tmpdir/first" "$tmpdir/first-again" >/dev/null; then
  printf 'expected jshon -e 0 to be stable across calls\n' >&2
  exit 1
fi
