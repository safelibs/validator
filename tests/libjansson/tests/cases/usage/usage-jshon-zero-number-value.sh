#!/usr/bin/env bash
# @testcase: usage-jshon-zero-number-value
# @title: jshon zero number value
# @description: Reads a zero JSON number field with jshon and verifies the emitted numeric value is zero.
# @timeout: 180
# @tags: usage, json, jshon
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-zero-number-value"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

run_jshon() {
  printf '%s' "$1" | jshon "${@:2}" >"$tmpdir/out"
}

run_jshon '{"value":0}' -e value -u
validator_assert_contains "$tmpdir/out" '0'
