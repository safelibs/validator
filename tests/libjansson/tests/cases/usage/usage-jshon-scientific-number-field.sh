#!/usr/bin/env bash
# @testcase: usage-jshon-scientific-number-field
# @title: jshon scientific number field
# @description: Reads a scientific-notation number with jshon and verifies the decoded numeric output.
# @timeout: 180
# @tags: usage, json, jshon
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-scientific-number-field"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

run_jshon() {
  printf '%s' "$1" | jshon "${@:2}" >"$tmpdir/out"
}

run_jshon '{"ratio":1.25e3}' -e ratio -u
validator_assert_contains "$tmpdir/out" '1250'
