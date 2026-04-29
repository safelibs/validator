#!/usr/bin/env bash
# @testcase: usage-jshon-file-root-object
# @title: jshon file root object
# @description: Reads a JSON file with jshon and verifies the root type remains object.
# @timeout: 180
# @tags: usage, json
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-file-root-object"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

json='{"name":"demo","count":7,"active":true,"disabled":false,"empty":null,"items":[1,2,3],"records":[{"name":"alpha"},{"name":"beta"}],"nested":{"value":"ok","label":"hello world"}}'
run_jshon() {
  printf '%s' "$1" | jshon "${@:2}" >"$tmpdir/out"
}

printf '%s' "$json" >"$tmpdir/input.json"
jshon -F "$tmpdir/input.json" -t >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'object'
