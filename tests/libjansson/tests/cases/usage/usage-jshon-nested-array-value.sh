#!/usr/bin/env bash
# @testcase: usage-jshon-nested-array-value
# @title: jshon nested array value
# @description: Extracts a value from an object inside a JSON array with jshon.
# @timeout: 180
# @tags: usage, json
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-nested-array-value"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

json='{"name":"demo","count":7,"active":true,"disabled":false,"empty":null,"items":[1,2,3],"records":[{"name":"alpha"},{"name":"beta"}],"nested":{"value":"ok","label":"hello world"}}'
run_jshon() {
  printf '%s' "$1" | jshon "${@:2}" >"$tmpdir/out"
}

run_jshon "$json" -e records -e 1 -e name -u
validator_assert_contains "$tmpdir/out" 'beta'
