#!/usr/bin/env bash
# @testcase: usage-jshon-bool-false-type
# @title: jshon bool false type
# @description: Reads a false boolean field with jshon and verifies that the selected value reports the boolean type.
# @timeout: 180
# @tags: usage, json, jshon
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-bool-false-type"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

run_jshon() {
  printf '%s' "$1" | jshon "${@:2}" >"$tmpdir/out"
}

run_jshon '{"active":false}' -e active -t
validator_assert_contains "$tmpdir/out" 'bool'
