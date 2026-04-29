#!/usr/bin/env bash
# @testcase: usage-jshon-root-array-length
# @title: jshon reports root array length
# @description: Reads a root array document and verifies its element count.
# @timeout: 120
# @tags: usage, json
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-root-array-length"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

json='{"name":"demo","count":7,"active":true,"items":[1,2,3],"nested":{"value":"ok"}}'

run_jshon() {
  printf '%s' "$1" | jshon "${@:2}" >"$tmpdir/out"
}

run_jshon '[1,2,3,4]' -l
validator_assert_contains "$tmpdir/out" '4'
