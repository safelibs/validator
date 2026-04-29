#!/usr/bin/env bash
# @testcase: usage-jshon-file-array-length
# @title: jshon file array length
# @description: Reads a JSON array from a file with jshon and verifies the reported array length.
# @timeout: 180
# @tags: usage, json, jshon
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-file-array-length"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

run_jshon() {
  printf '%s' "$1" | jshon "${@:2}" >"$tmpdir/out"
}

printf '%s' '[1,2,3,4,5]' >"$tmpdir/input.json"
jshon -F "$tmpdir/input.json" -l >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" '5'
