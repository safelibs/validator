#!/usr/bin/env bash
# @testcase: usage-jshon-empty-object-length
# @title: jshon empty object length
# @description: Measures the length of an empty root JSON object with jshon and verifies the result is zero.
# @timeout: 180
# @tags: usage, json
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-empty-object-length"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

run_jshon() {
  printf '%s' "$1" | jshon "${@:2}" >"$tmpdir/out"
}

run_jshon '{}' -l
grep -Fxq '0' "$tmpdir/out"
