#!/usr/bin/env bash
# @testcase: usage-jshon-negative-number-field
# @title: jshon negative number field
# @description: Reads a negative numeric field with jshon and verifies the emitted value.
# @timeout: 180
# @tags: usage, json, jshon
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-negative-number-field"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

run_jshon() {
  printf '%s' "$1" | jshon "${@:2}" >"$tmpdir/out"
}

run_jshon '{"delta":-5}' -e delta -u
validator_assert_contains "$tmpdir/out" '-5'
