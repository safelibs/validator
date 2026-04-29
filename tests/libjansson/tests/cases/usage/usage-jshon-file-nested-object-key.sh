#!/usr/bin/env bash
# @testcase: usage-jshon-file-nested-object-key
# @title: jshon file nested object key
# @description: Reads a deeply nested object value from a JSON file with jshon and verifies the selected label string.
# @timeout: 180
# @tags: usage, json, jshon
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-file-nested-object-key"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

run_jshon() {
  printf '%s' "$1" | jshon "${@:2}" >"$tmpdir/out"
}

printf '{"outer":{"inner":{"label":"validator"}}}' >"$tmpdir/input.json"
jshon -F "$tmpdir/input.json" -e outer -e inner -e label -u >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'validator'
