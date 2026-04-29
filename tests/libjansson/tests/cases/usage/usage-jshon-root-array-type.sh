#!/usr/bin/env bash
# @testcase: usage-jshon-root-array-type
# @title: jshon reports root array type
# @description: Reads a root array document and verifies the reported JSON type.
# @timeout: 120
# @tags: usage, json
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-root-array-type"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

json='{"name":"demo","count":7,"active":true,"items":[1,2,3],"nested":{"value":"ok"}}'

run_jshon() {
  printf '%s' "$1" | jshon "${@:2}" >"$tmpdir/out"
}

run_jshon '[1,2,3]' -t
validator_assert_contains "$tmpdir/out" 'array'
