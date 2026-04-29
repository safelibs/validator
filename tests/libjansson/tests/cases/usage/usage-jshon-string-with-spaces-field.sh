#!/usr/bin/env bash
# @testcase: usage-jshon-string-with-spaces-field
# @title: jshon string with spaces field
# @description: Reads a JSON string field containing whitespace with jshon and verifies the emitted phrase preserves the embedded space.
# @timeout: 180
# @tags: usage, json, jshon
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-string-with-spaces-field"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

run_jshon() {
  printf '%s' "$1" | jshon "${@:2}" >"$tmpdir/out"
}

run_jshon '{"phrase":"hello world"}' -e phrase -u
validator_assert_contains "$tmpdir/out" 'hello world'
