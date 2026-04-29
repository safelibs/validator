#!/usr/bin/env bash
# @testcase: usage-jshon-object-array-third-id
# @title: jshon object array third id
# @description: Reads a field from the third object in an array with jshon and verifies the selected identifier.
# @timeout: 180
# @tags: usage, json, jshon
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-object-array-third-id"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

run_jshon() {
  printf '%s' "$1" | jshon "${@:2}" >"$tmpdir/out"
}

run_jshon '{"items":[{"id":"a"},{"id":"b"},{"id":"c"}]}' -e items -e 2 -e id -u
validator_assert_contains "$tmpdir/out" 'c'
