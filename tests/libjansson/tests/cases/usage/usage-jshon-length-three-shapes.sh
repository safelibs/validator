#!/usr/bin/env bash
# @testcase: usage-jshon-length-three-shapes
# @title: jshon length on array object and string
# @description: Compares the -l count produced for an array, an object, and a string of distinct sizes.
# @timeout: 120
# @tags: usage, json
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-length-three-shapes"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

json='{"arr":[10,20,30,40],"obj":{"a":1,"b":2,"c":3},"str":"abcdefghij"}'

probe() {
  local key=$1
  local expected=$2
  printf '%s' "$json" | jshon -e "$key" -l >"$tmpdir/out"
  if ! grep -Fxq -- "$expected" "$tmpdir/out"; then
    printf 'expected length %s for %s, got:\n' "$expected" "$key" >&2
    cat "$tmpdir/out" >&2
    exit 1
  fi
}

probe arr 4
probe obj 3
probe str 10
