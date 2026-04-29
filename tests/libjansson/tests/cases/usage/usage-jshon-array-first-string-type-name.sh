#!/usr/bin/env bash
# @testcase: usage-jshon-array-first-string-type-name
# @title: jshon array first string type
# @description: Parses a JSON array with jshon, selects the first string element, and verifies the reported element type is string.
# @timeout: 180
# @tags: usage, json, jshon
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-array-first-string-type-name"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

run_jshon() {
  printf '%s' "$1" | jshon "${@:2}" >"$tmpdir/out"
}

run_jshon '["validator","beta"]' -e 0 -t
validator_assert_contains "$tmpdir/out" 'string'
