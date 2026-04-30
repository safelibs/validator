#!/usr/bin/env bash
# @testcase: usage-jshon-2d-array-walk
# @title: jshon walks a 2D array
# @description: Indexes into a 2D array of integers via repeated -e and verifies multiple element values.
# @timeout: 120
# @tags: usage, json
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-2d-array-walk"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

json='{"grid":[[10,11,12],[20,21,22],[30,31,32]]}'

probe() {
  local row=$1
  local col=$2
  local expected=$3
  printf '%s' "$json" | jshon -e grid -e "$row" -e "$col" -u >"$tmpdir/out"
  if ! grep -Fxq -- "$expected" "$tmpdir/out"; then
    printf 'expected grid[%s][%s]=%s, got:\n' "$row" "$col" "$expected" >&2
    cat "$tmpdir/out" >&2
    exit 1
  fi
}

probe 0 0 10
probe 1 2 22
probe 2 1 31

# Outer array length is 3, each inner row has length 3.
printf '%s' "$json" | jshon -e grid -l >"$tmpdir/outer"
validator_assert_contains "$tmpdir/outer" '3'
printf '%s' "$json" | jshon -e grid -e 1 -l >"$tmpdir/inner"
validator_assert_contains "$tmpdir/inner" '3'
