#!/usr/bin/env bash
# @testcase: usage-jshon-nested-object-key-list
# @title: jshon nested object key list
# @description: Lists keys from a nested JSON object with jshon and verifies the expected nested keys appear.
# @timeout: 180
# @tags: usage, json, jshon
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-nested-object-key-list"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

run_jshon() {
  printf '%s' "$1" | jshon "${@:2}" >"$tmpdir/out"
}

run_jshon '{"meta":{"count":2,"name":"validator"}}' -e meta -k
validator_assert_contains "$tmpdir/out" 'count'
validator_assert_contains "$tmpdir/out" 'name'
