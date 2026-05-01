#!/usr/bin/env bash
# @testcase: usage-jshon-r7-insert-into-nested-array
# @title: jshon insert into a nested array via -e then -i append
# @description: Descends into the nested array under key items with -e, pushes a new number with -n 99, appends it with -i append, and verifies the emitted document is the modified items array of length four whose tail element is 99 while head element is preserved.
# @timeout: 120
# @tags: usage, json, jshon
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-r7-insert-into-nested-array"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

json='{"name":"box","items":[1,2,3]}'

# After -e navigates into items, -i append operates on that subdoc and emits it.
result=$(printf '%s' "$json" | jshon -e items -n 99 -i append)
printf '%s' "$result" >"$tmpdir/r.json"

# Resulting top-level should be an array.
jshon -F "$tmpdir/r.json" -t >"$tmpdir/itype"
grep -Fxq -- 'array' "$tmpdir/itype" || {
  printf 'expected top-level array, got:\n' >&2
  cat "$tmpdir/itype" >&2
  exit 1
}

# Length is 4.
jshon -F "$tmpdir/r.json" -l >"$tmpdir/ilen"
grep -Fxq -- '4' "$tmpdir/ilen" || {
  printf 'expected length 4, got:\n' >&2
  cat "$tmpdir/ilen" >&2
  exit 1
}

# Tail value (index 3) is 99.
jshon -F "$tmpdir/r.json" -e 3 -u >"$tmpdir/v3"
grep -Fxq -- '99' "$tmpdir/v3" || {
  printf 'expected 99 at index 3, got:\n' >&2
  cat "$tmpdir/v3" >&2
  exit 1
}

# Original head value preserved.
jshon -F "$tmpdir/r.json" -e 0 -u >"$tmpdir/v0"
grep -Fxq -- '1' "$tmpdir/v0" || {
  printf 'expected 1 at index 0, got:\n' >&2
  cat "$tmpdir/v0" >&2
  exit 1
}
