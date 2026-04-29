#!/usr/bin/env bash
# @testcase: usage-jshon-file-root-string-value
# @title: jshon file root string value
# @description: Loads a JSON file containing a root string and verifies the unquoted root value with jshon.
# @timeout: 180
# @tags: usage, json, jshon
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-file-root-string-value"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

run_jshon() {
  printf '%s' "$1" | jshon "${@:2}" >"$tmpdir/out"
}

printf '{"value":"plain-string"}' >"$tmpdir/input.json"
jshon -F "$tmpdir/input.json" -e value -u >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'plain-string'
