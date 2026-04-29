#!/usr/bin/env bash
# @testcase: usage-jshon-array-values
# @title: jshon prints array values
# @description: Expands array values from JSON input and verifies each scalar is printed.
# @timeout: 120
# @tags: usage, json
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-array-values"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

json='{"name":"demo","count":7,"active":true,"items":[1,2,3],"nested":{"value":"ok"}}'

run_jshon() {
  printf '%s' "$1" | jshon "${@:2}" >"$tmpdir/out"
}

run_jshon "$json" -e items -a -u
validator_assert_contains "$tmpdir/out" '1'
validator_assert_contains "$tmpdir/out" '3'
