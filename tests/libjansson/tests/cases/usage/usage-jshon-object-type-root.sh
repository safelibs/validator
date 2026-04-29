#!/usr/bin/env bash
# @testcase: usage-jshon-object-type-root
# @title: jshon object root type
# @description: Reads the top-level type of a JSON object with jshon and verifies the reported type is object.
# @timeout: 180
# @tags: usage, json, jshon
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-object-type-root"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

run_jshon() {
  printf '%s' "$1" | jshon "${@:2}" >"$tmpdir/out"
}

run_jshon '{"alpha":1}' -t
validator_assert_contains "$tmpdir/out" 'object'
