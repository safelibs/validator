#!/usr/bin/env bash
# @testcase: usage-jshon-r3-build-array-incrementally
# @title: jshon builds an array from scratch via -n -s -n -i append chaining
# @description: Starts from an empty array via jshon -n '[]' and appends a string, a number, a boolean, and a null in sequence with repeated -s/-n + -i append, then verifies the final array length and the type of each appended element.
# @timeout: 120
# @tags: usage, json, jshon
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-r3-build-array-incrementally"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Build [] then append "alpha", 42, true, null in order.
result=$(jshon -n '[]' \
  -s 'alpha' -i append \
  -n '42'    -i append \
  -n 'true'  -i append \
  -n 'null'  -i append)

printf '%s' "$result" >"$tmpdir/built.json"

# Length must be 4.
jshon -F "$tmpdir/built.json" -l >"$tmpdir/len"
grep -Fxq -- '4' "$tmpdir/len" || {
  printf 'expected length 4, got:\n' >&2
  cat "$tmpdir/len" >&2
  exit 1
}

# Element 0 type=string and value=alpha.
jshon -F "$tmpdir/built.json" -e 0 -t >"$tmpdir/t0"
grep -Fxq -- 'string' "$tmpdir/t0" || {
  printf 'expected element 0 to be string, got:\n' >&2
  cat "$tmpdir/t0" >&2
  exit 1
}
jshon -F "$tmpdir/built.json" -e 0 -u >"$tmpdir/v0"
grep -Fxq -- 'alpha' "$tmpdir/v0" || {
  printf 'expected element 0 value alpha, got:\n' >&2
  cat "$tmpdir/v0" >&2
  exit 1
}

# Element 1 type=number, value=42.
jshon -F "$tmpdir/built.json" -e 1 -t >"$tmpdir/t1"
grep -Fxq -- 'number' "$tmpdir/t1" || {
  printf 'expected element 1 to be number, got:\n' >&2
  cat "$tmpdir/t1" >&2
  exit 1
}
jshon -F "$tmpdir/built.json" -e 1 -u >"$tmpdir/v1"
grep -Fxq -- '42' "$tmpdir/v1" || {
  printf 'expected element 1 value 42, got:\n' >&2
  cat "$tmpdir/v1" >&2
  exit 1
}

# Element 2 type=bool.
jshon -F "$tmpdir/built.json" -e 2 -t >"$tmpdir/t2"
grep -Fxq -- 'bool' "$tmpdir/t2" || {
  printf 'expected element 2 to be bool, got:\n' >&2
  cat "$tmpdir/t2" >&2
  exit 1
}

# Element 3 type=null.
jshon -F "$tmpdir/built.json" -e 3 -t >"$tmpdir/t3"
grep -Fxq -- 'null' "$tmpdir/t3" || {
  printf 'expected element 3 to be null, got:\n' >&2
  cat "$tmpdir/t3" >&2
  exit 1
}
