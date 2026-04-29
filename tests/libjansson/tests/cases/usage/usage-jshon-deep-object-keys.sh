#!/usr/bin/env bash
# @testcase: usage-jshon-deep-object-keys
# @title: jshon deep object keys
# @description: Extracts a nested object and verifies jshon key listing output.
# @timeout: 180
# @tags: usage, json
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-deep-object-keys"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

json='{"name":"demo","count":7,"active":true,"disabled":false,"empty":null,"items":[1,2,3],"records":[{"name":"alpha"},{"name":"beta"}],"nested":{"value":"ok","label":"hello world"}}'
run_jshon() {
  printf '%s' "$1" | jshon "${@:2}" >"$tmpdir/out"
}

run_jshon "$json" -e nested -k
validator_assert_contains "$tmpdir/out" 'label'
validator_assert_contains "$tmpdir/out" 'value'
