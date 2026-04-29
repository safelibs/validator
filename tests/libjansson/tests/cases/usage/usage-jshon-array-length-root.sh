#!/usr/bin/env bash
# @testcase: usage-jshon-array-length-root
# @title: jshon array root length
# @description: Counts the elements of a six-item root JSON array with jshon and verifies the reported length.
# @timeout: 180
# @tags: usage, json, jshon
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-array-length-root"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

run_jshon() {
  printf '%s' "$1" | jshon "${@:2}" >"$tmpdir/out"
}

run_jshon '[10, 20, 30, 40, 50, 60]' -l
validator_assert_contains "$tmpdir/out" '6'
