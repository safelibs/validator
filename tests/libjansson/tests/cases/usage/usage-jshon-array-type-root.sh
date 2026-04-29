#!/usr/bin/env bash
# @testcase: usage-jshon-array-type-root
# @title: jshon array root type
# @description: Reads the top-level type of a JSON array with jshon and verifies the reported type is array.
# @timeout: 180
# @tags: usage, json, jshon
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-array-type-root"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

run_jshon() {
  printf '%s' "$1" | jshon "${@:2}" >"$tmpdir/out"
}

run_jshon '[1, 2, 3]' -t
validator_assert_contains "$tmpdir/out" 'array'
