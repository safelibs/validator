#!/usr/bin/env bash
# @testcase: usage-jshon-deep-array-length
# @title: jshon deep array length
# @description: Measures the length of a nested array with jshon and verifies the element count.
# @timeout: 180
# @tags: usage, json, jshon
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-deep-array-length"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

run_jshon() {
  printf '%s' "$1" | jshon "${@:2}" >"$tmpdir/out"
}

run_jshon '{"matrix":[[1,2],[3,4],[5,6]]}' -e matrix -l
validator_assert_contains "$tmpdir/out" '3'
