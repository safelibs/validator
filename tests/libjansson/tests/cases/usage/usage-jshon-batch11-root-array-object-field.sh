#!/usr/bin/env bash
# @testcase: usage-jshon-batch11-root-array-object-field
# @title: jshon root array object field
# @description: Reads an object field from a root JSON array with jshon.
# @timeout: 180
# @tags: usage, json, cli
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-batch11-root-array-object-field"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

run_jshon() {
  printf '%s' "$1" | jshon "${@:2}" >"$tmpdir/out"
}

json='{"meta":{"enabled":true,"missing":null,"hyphen-key":"dash"},"matrix":[[1,2],[3,4]],"records":[{"name":"alpha","score":1.5},{"name":"beta","score":2.5}],"text":"a/b c","number":-12.5}'

run_jshon '[{"id":"first"},{"id":"second"}]' -e 1 -e id -u
validator_assert_contains "$tmpdir/out" 'second'
