#!/usr/bin/env bash
# @testcase: usage-jshon-batch11-hyphen-key-field
# @title: jshon hyphen key field
# @description: Reads an object key containing a hyphen with jshon.
# @timeout: 180
# @tags: usage, json, cli
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-batch11-hyphen-key-field"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

run_jshon() {
  printf '%s' "$1" | jshon "${@:2}" >"$tmpdir/out"
}

json='{"meta":{"enabled":true,"missing":null,"hyphen-key":"dash"},"matrix":[[1,2],[3,4]],"records":[{"name":"alpha","score":1.5},{"name":"beta","score":2.5}],"text":"a/b c","number":-12.5}'

run_jshon "$json" -e meta -e hyphen-key -u
validator_assert_contains "$tmpdir/out" 'dash'
