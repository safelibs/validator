#!/usr/bin/env bash
# @testcase: usage-jshon-r7-insert-into-nested-array
# @title: jshon insert into a nested array via -e then -i append
# @description: Descends into the nested array under key items with -e, pushes a new number with -n 99, inserts it at append position with -i append, then verifies the parent object still contains items as an array of length four whose tail element is the inserted 99.
# @timeout: 120
# @tags: usage, json, jshon
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-r7-insert-into-nested-array"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

json='{"name":"box","items":[1,2,3]}'

# Note: -i append on a nested array operates on the navigated value and emits
# the modified root document.
result=$(printf '%s' "$json" | jshon -e items -n 99 -i append)
printf '%s' "$result" >"$tmpdir/r.json"

# Root keys unchanged.
jshon -F "$tmpdir/r.json" -l >"$tmpdir/rlen"
grep -Fxq -- '2' "$tmpdir/rlen" || {
  printf 'expected root length 2, got:\n' >&2
  cat "$tmpdir/rlen" >&2
  exit 1
}

# items is still array.
jshon -F "$tmpdir/r.json" -e items -t >"$tmpdir/itype"
grep -Fxq -- 'array' "$tmpdir/itype" || {
  printf 'expected items to be array, got:\n' >&2
  cat "$tmpdir/itype" >&2
  exit 1
}

# items length is 4.
jshon -F "$tmpdir/r.json" -e items -l >"$tmpdir/ilen"
grep -Fxq -- '4' "$tmpdir/ilen" || {
  printf 'expected items length 4, got:\n' >&2
  cat "$tmpdir/ilen" >&2
  exit 1
}

# Tail value (index 3) is 99.
jshon -F "$tmpdir/r.json" -e items -e 3 -u >"$tmpdir/v3"
grep -Fxq -- '99' "$tmpdir/v3" || {
  printf 'expected 99 at items[3], got:\n' >&2
  cat "$tmpdir/v3" >&2
  exit 1
}

# Original head value preserved.
jshon -F "$tmpdir/r.json" -e items -e 0 -u >"$tmpdir/v0"
grep -Fxq -- '1' "$tmpdir/v0" || {
  printf 'expected 1 at items[0], got:\n' >&2
  cat "$tmpdir/v0" >&2
  exit 1
}
