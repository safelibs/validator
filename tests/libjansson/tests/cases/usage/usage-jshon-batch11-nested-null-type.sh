#!/usr/bin/env bash
# @testcase: usage-jshon-batch11-nested-null-type
# @title: jshon nested null type
# @description: Reads a nested null field with jshon and checks its reported type.
# @timeout: 180
# @tags: usage, json, cli
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-batch11-nested-null-type"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

run_jshon() {
  printf '%s' "$1" | jshon "${@:2}" >"$tmpdir/out"
}

json='{"meta":{"enabled":true,"missing":null,"hyphen-key":"dash"},"matrix":[[1,2],[3,4]],"records":[{"name":"alpha","score":1.5},{"name":"beta","score":2.5}],"text":"a/b c","number":-12.5}'

run_jshon "$json" -e meta -e missing -t
validator_assert_contains "$tmpdir/out" 'null'
