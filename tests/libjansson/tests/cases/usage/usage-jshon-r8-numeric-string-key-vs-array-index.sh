#!/usr/bin/env bash
# @testcase: usage-jshon-r8-numeric-string-key-vs-array-index
# @title: jshon -e treats a numeric-looking object key as a string and an array index as integer
# @description: Constructs an object whose keys are the digit strings 123 and 456 plus an array of three numbers, and verifies that jshon -e 123 against the object returns the value bound to the string key while jshon -e 1 against the array returns the second element by integer index, demonstrating that the same -e argument is interpreted by container type rather than by the literal characters supplied.
# @timeout: 120
# @tags: usage, json, jshon
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-r8-numeric-string-key-vs-array-index"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

obj='{"123":"alpha","456":"beta","789":"gamma"}'
arr='[10,20,30]'

# Object: -e 123 returns the string bound to key "123".
printf '%s' "$obj" | jshon -e 123 -u >"$tmpdir/obj123"
grep -Fxq -- 'alpha' "$tmpdir/obj123" || {
  printf 'expected alpha for object key 123, got:\n' >&2
  cat "$tmpdir/obj123" >&2
  exit 1
}

# Object: -e 456 returns beta.
printf '%s' "$obj" | jshon -e 456 -u >"$tmpdir/obj456"
grep -Fxq -- 'beta' "$tmpdir/obj456" || {
  printf 'expected beta for object key 456, got:\n' >&2
  cat "$tmpdir/obj456" >&2
  exit 1
}

# Array: -e 1 returns the integer 20 at index 1.
printf '%s' "$arr" | jshon -e 1 -u >"$tmpdir/arr1"
grep -Fxq -- '20' "$tmpdir/arr1" || {
  printf 'expected 20 at array index 1, got:\n' >&2
  cat "$tmpdir/arr1" >&2
  exit 1
}

# Array: -e -1 (negative wrap-around) returns the last element 30.
printf '%s' "$arr" | jshon -e -1 -u >"$tmpdir/arrlast"
grep -Fxq -- '30' "$tmpdir/arrlast" || {
  printf 'expected 30 at array index -1, got:\n' >&2
  cat "$tmpdir/arrlast" >&2
  exit 1
}

# Object: -e on a digit string that is NOT a key should fail.
set +e
printf '%s' "$obj" | jshon -e 999 -u >"$tmpdir/missing-out" 2>"$tmpdir/missing-err"
rc=$?
set -e
if [[ "$rc" -eq 0 ]]; then
  printf 'expected non-zero exit on missing numeric-string key 999, got %s\n' "$rc" >&2
  exit 1
fi
