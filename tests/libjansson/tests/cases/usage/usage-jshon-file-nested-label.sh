#!/usr/bin/env bash
# @testcase: usage-jshon-file-nested-label
# @title: jshon file nested label
# @description: Reads a nested string field from a JSON file with jshon and verifies the label text.
# @timeout: 180
# @tags: usage, json
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-file-nested-label"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

json='{"name":"demo","count":7,"active":true,"disabled":false,"empty":null,"items":[1,2,3],"records":[{"name":"alpha"},{"name":"beta"}],"nested":{"value":"ok","label":"hello world"}}'
run_jshon() {
  printf '%s' "$1" | jshon "${@:2}" >"$tmpdir/out"
}

printf '%s' "$json" >"$tmpdir/input.json"
jshon -F "$tmpdir/input.json" -e nested -e label -u >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'hello world'
