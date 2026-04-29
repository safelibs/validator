#!/usr/bin/env bash
# @testcase: usage-jshon-file-nested-array-length
# @title: jshon file nested array length
# @description: Loads a file-backed nested array with jshon and verifies the reported length.
# @timeout: 180
# @tags: usage, json, jshon
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-file-nested-array-length"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

run_jshon() {
  printf '%s' "$1" | jshon "${@:2}" >"$tmpdir/out"
}

printf '{"outer":{"items":[10,20,30,40]}}' >"$tmpdir/input.json"
jshon -F "$tmpdir/input.json" -e outer -e items -l >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" '4'
