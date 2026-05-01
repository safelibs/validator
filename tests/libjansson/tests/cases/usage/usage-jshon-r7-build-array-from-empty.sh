#!/usr/bin/env bash
# @testcase: usage-jshon-r7-build-array-from-empty
# @title: jshon builds an array from -n array via repeated -i append
# @description: Starts with jshon -n array and appends three numeric elements using -n <num> -i append, then verifies the resulting array has length three with values 7, 8, 9 at positions 0, 1, 2 respectively.
# @timeout: 120
# @tags: usage, json, jshon
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-r7-build-array-from-empty"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

result=$(jshon -n array \
  -n 7 -i append \
  -n 8 -i append \
  -n 9 -i append)
printf '%s' "$result" >"$tmpdir/arr.json"

# Type is array.
jshon -F "$tmpdir/arr.json" -t >"$tmpdir/type"
grep -Fxq -- 'array' "$tmpdir/type" || {
  printf 'expected array type, got:\n' >&2
  cat "$tmpdir/type" >&2
  exit 1
}

# Length is exactly 3.
jshon -F "$tmpdir/arr.json" -l >"$tmpdir/len"
grep -Fxq -- '3' "$tmpdir/len" || {
  printf 'expected length 3, got:\n' >&2
  cat "$tmpdir/len" >&2
  exit 1
}

# Values appear in append order at indices 0,1,2.
for pair in '0:7' '1:8' '2:9'; do
  idx=${pair%%:*}; want=${pair##*:}
  jshon -F "$tmpdir/arr.json" -e "$idx" -u >"$tmpdir/v-$idx"
  if ! grep -Fxq -- "$want" "$tmpdir/v-$idx"; then
    printf 'expected %s at index %s, got:\n' "$want" "$idx" >&2
    cat "$tmpdir/v-$idx" >&2
    exit 1
  fi
done
