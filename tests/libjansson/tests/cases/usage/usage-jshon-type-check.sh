#!/usr/bin/env bash
# @testcase: usage-jshon-type-check
# @title: jshon reports value type
# @description: Checks that jshon reports a boolean member as a JSON bool.
# @timeout: 120
# @tags: usage, json
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-type-check"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

json='{"name":"demo","count":7,"active":true,"items":[1,2,3],"nested":{"value":"ok"}}'

run_jshon() {
  printf '%s' "$1" | jshon "${@:2}" >"$tmpdir/out"
}

run_jshon "$json" -e active -t
validator_assert_contains "$tmpdir/out" 'bool'
