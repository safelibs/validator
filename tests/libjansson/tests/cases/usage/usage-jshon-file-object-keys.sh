#!/usr/bin/env bash
# @testcase: usage-jshon-file-object-keys
# @title: jshon file object keys
# @description: Reads a JSON object from a file with jshon and verifies the emitted key list contains both object keys.
# @timeout: 180
# @tags: usage, json, jshon
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-file-object-keys"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

run_jshon() {
  printf '%s' "$1" | jshon "${@:2}" >"$tmpdir/out"
}

printf '%s' '{"alpha":1,"beta":2}' >"$tmpdir/input.json"
jshon -F "$tmpdir/input.json" -k >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'alpha'
validator_assert_contains "$tmpdir/out" 'beta'
