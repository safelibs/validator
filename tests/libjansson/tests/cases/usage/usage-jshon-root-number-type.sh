#!/usr/bin/env bash
# @testcase: usage-jshon-root-number-type
# @title: jshon root number type
# @description: Checks the JSON type of a numeric root value with jshon.
# @timeout: 180
# @tags: usage, json, jshon
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-root-number-type"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

run_jshon() {
  printf '%s' "$1" | jshon "${@:2}" >"$tmpdir/out"
}

run_jshon '{"value":42}' -e value -t
validator_assert_contains "$tmpdir/out" 'number'
