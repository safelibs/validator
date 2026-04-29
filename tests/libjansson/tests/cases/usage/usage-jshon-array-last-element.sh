#!/usr/bin/env bash
# @testcase: usage-jshon-array-last-element
# @title: jshon array last element
# @description: Reads the fourth element from a JSON array with jshon and verifies the emitted string value.
# @timeout: 180
# @tags: usage, json, jshon
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-array-last-element"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

run_jshon() {
  printf '%s' "$1" | jshon "${@:2}" >"$tmpdir/out"
}

run_jshon '{"items":["alpha","beta","gamma","delta"]}' -e items -e 3 -u
validator_assert_contains "$tmpdir/out" 'delta'
