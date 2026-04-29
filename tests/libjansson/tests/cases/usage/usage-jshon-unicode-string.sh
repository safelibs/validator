#!/usr/bin/env bash
# @testcase: usage-jshon-unicode-string
# @title: jshon unicode string
# @description: Extracts a JSON string containing escaped Unicode through jshon and verifies the decoded text is emitted.
# @timeout: 180
# @tags: usage, json
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-unicode-string"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

run_jshon() {
  printf '%s' "$1" | jshon "${@:2}" >"$tmpdir/out"
}

run_jshon '{"label":"snowman \\u2603"}' -e label -u
validator_assert_contains "$tmpdir/out" 'snowman'
