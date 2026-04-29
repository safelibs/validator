#!/usr/bin/env bash
# @testcase: usage-jshon-file-unicode-label
# @title: jshon file unicode label
# @description: Exercises jshon file unicode label through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-file-unicode-label"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

json='{"name":"demo","count":7,"ratio":1.5,"items":[1,2,3],"records":[{"name":"alpha"},{"name":"beta"}],"nested":{"empty":[],"child":{"label":"ok"}}}'
run_jshon() {
  printf '%s' "$1" | jshon "${@:2}" >"$tmpdir/out"
}

printf '{"label":"snowman \\u2603"}' >"$tmpdir/input.json"
jshon -F "$tmpdir/input.json" -e label -u >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'snowman'
