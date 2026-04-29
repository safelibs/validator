#!/usr/bin/env bash
# @testcase: usage-jshon-name-field
# @title: jshon name field
# @description: Reads a top-level JSON string field with jshon and verifies the extracted value.
# @timeout: 180
# @tags: usage, json
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-name-field"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

json='{"name":"demo","count":7,"active":true,"disabled":false,"empty":null,"items":[1,2,3],"records":[{"name":"alpha"},{"name":"beta"}],"nested":{"value":"ok","label":"hello world"}}'
run_jshon() {
  printf '%s' "$1" | jshon "${@:2}" >"$tmpdir/out"
}

run_jshon "$json" -e name -u
validator_assert_contains "$tmpdir/out" 'demo'
