#!/usr/bin/env bash
# @testcase: usage-jshon-array-second-value
# @title: jshon array second value
# @description: Reads the second element from a JSON array with jshon and verifies the selected array value.
# @timeout: 180
# @tags: usage, json, jshon
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-array-second-value"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

run_jshon() {
  printf '%s' "$1" | jshon "${@:2}" >"$tmpdir/out"
}

run_jshon '{"items":["alpha","beta","gamma"]}' -e items -e 1 -u
validator_assert_contains "$tmpdir/out" 'beta'
