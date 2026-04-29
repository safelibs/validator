#!/usr/bin/env bash
# @testcase: usage-jshon-batch11-nested-bool-unstring
# @title: jshon nested bool unstring
# @description: Reads a nested boolean value with jshon and emits it unquoted.
# @timeout: 180
# @tags: usage, json, cli
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-batch11-nested-bool-unstring"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

run_jshon() {
  printf '%s' "$1" | jshon "${@:2}" >"$tmpdir/out"
}

json='{"meta":{"enabled":true,"missing":null,"hyphen-key":"dash"},"matrix":[[1,2],[3,4]],"records":[{"name":"alpha","score":1.5},{"name":"beta","score":2.5}],"text":"a/b c","number":-12.5}'

run_jshon "$json" -e meta -e enabled -u
validator_assert_contains "$tmpdir/out" 'true'
