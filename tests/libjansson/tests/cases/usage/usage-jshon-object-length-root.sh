#!/usr/bin/env bash
# @testcase: usage-jshon-object-length-root
# @title: jshon object root length
# @description: Counts the keys of a four-key root JSON object with jshon and verifies the reported length.
# @timeout: 180
# @tags: usage, json, jshon
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-object-length-root"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

run_jshon() {
  printf '%s' "$1" | jshon "${@:2}" >"$tmpdir/out"
}

run_jshon '{"a":1,"b":2,"c":3,"d":4}' -l
validator_assert_contains "$tmpdir/out" '4'
