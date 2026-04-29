#!/usr/bin/env bash
# @testcase: usage-jshon-negative-number-value
# @title: jshon negative number value
# @description: Reads a negative JSON number with jshon and verifies the emitted numeric value is preserved.
# @timeout: 180
# @tags: usage, json, jshon
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-negative-number-value"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

run_jshon() {
  printf '%s' "$1" | jshon "${@:2}" >"$tmpdir/out"
}

run_jshon '{"delta":-12}' -e delta -u
validator_assert_contains "$tmpdir/out" '-12'
