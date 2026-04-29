#!/usr/bin/env bash
# @testcase: usage-jshon-escaped-string
# @title: jshon escaped string
# @description: Extracts a JSON string containing escape sequences with jshon and verifies the unescaped text is emitted.
# @timeout: 180
# @tags: usage, json
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-escaped-string"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

run_jshon() {
  printf '%s' "$1" | jshon "${@:2}" >"$tmpdir/out"
}

run_jshon '{"line":"alpha\\nbeta"}' -e line -u
validator_assert_contains "$tmpdir/out" 'alpha'
validator_assert_contains "$tmpdir/out" 'beta'
