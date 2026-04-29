#!/usr/bin/env bash
# @testcase: usage-jshon-boolean-array-values
# @title: jshon boolean array values
# @description: Expands a JSON boolean array with jshon and verifies true and false values are emitted.
# @timeout: 180
# @tags: usage, json
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-boolean-array-values"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

run_jshon() {
  printf '%s' "$1" | jshon "${@:2}" >"$tmpdir/out"
}

run_jshon '[true,false,true]' -a -u
validator_assert_contains "$tmpdir/out" 'true'
validator_assert_contains "$tmpdir/out" 'false'
