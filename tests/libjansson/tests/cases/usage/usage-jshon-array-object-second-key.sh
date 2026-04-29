#!/usr/bin/env bash
# @testcase: usage-jshon-array-object-second-key
# @title: jshon array object second key
# @description: Reads a field from the second object in an array with jshon and verifies the selected value.
# @timeout: 180
# @tags: usage, json, jshon
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-array-object-second-key"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

run_jshon() {
  printf '%s' "$1" | jshon "${@:2}" >"$tmpdir/out"
}

run_jshon '{"rows":[{"id":1,"name":"alpha"},{"id":2,"name":"beta"}]}' -e rows -e 1 -e name -u
validator_assert_contains "$tmpdir/out" 'beta'
