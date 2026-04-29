#!/usr/bin/env bash
# @testcase: usage-jshon-root-key-list
# @title: jshon root key list
# @description: Lists top-level JSON keys with jshon and verifies multiple expected keys appear.
# @timeout: 180
# @tags: usage, json
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-root-key-list"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

json='{"name":"demo","count":7,"active":true,"disabled":false,"empty":null,"items":[1,2,3],"records":[{"name":"alpha"},{"name":"beta"}],"nested":{"value":"ok","label":"hello world"}}'
run_jshon() {
  printf '%s' "$1" | jshon "${@:2}" >"$tmpdir/out"
}

run_jshon "$json" -k
validator_assert_contains "$tmpdir/out" 'active'
validator_assert_contains "$tmpdir/out" 'name'
