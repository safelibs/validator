#!/usr/bin/env bash
# @testcase: usage-jshon-nested-array-third-value
# @title: jshon nested array third value
# @description: Reads the third value from a nested JSON array with jshon and verifies the extracted numeric payload.
# @timeout: 180
# @tags: usage, json, jshon
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-nested-array-third-value"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

run_jshon() {
  printf '%s' "$1" | jshon "${@:2}" >"$tmpdir/out"
}

run_jshon '{"outer":{"items":[10,20,30,40]}}' -e outer -e items -e 2 -u
validator_assert_contains "$tmpdir/out" '30'
