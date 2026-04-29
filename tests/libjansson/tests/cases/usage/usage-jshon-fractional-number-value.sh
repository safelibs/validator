#!/usr/bin/env bash
# @testcase: usage-jshon-fractional-number-value
# @title: jshon fractional number value
# @description: Reads a fractional JSON number with jshon and verifies the emitted decimal value is preserved.
# @timeout: 180
# @tags: usage, json, jshon
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-fractional-number-value"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

run_jshon() {
  printf '%s' "$1" | jshon "${@:2}" >"$tmpdir/out"
}

run_jshon '{"ratio":0.25}' -e ratio -u
validator_assert_contains "$tmpdir/out" '0.25'
