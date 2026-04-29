#!/usr/bin/env bash
# @testcase: usage-jshon-batch11-file-nested-number
# @title: jshon file nested number
# @description: Reads a nested numeric field from a JSON file with jshon.
# @timeout: 180
# @tags: usage, json, cli
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-batch11-file-nested-number"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

run_jshon() {
  printf '%s' "$1" | jshon "${@:2}" >"$tmpdir/out"
}

json='{"meta":{"enabled":true,"missing":null,"hyphen-key":"dash"},"matrix":[[1,2],[3,4]],"records":[{"name":"alpha","score":1.5},{"name":"beta","score":2.5}],"text":"a/b c","number":-12.5}'

printf '%s' "$json" >"$tmpdir/input.json"
jshon -F "$tmpdir/input.json" -e records -e 0 -e score -u >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" '1.5'
