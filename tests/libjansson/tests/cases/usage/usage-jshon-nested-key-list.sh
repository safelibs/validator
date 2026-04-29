#!/usr/bin/env bash
# @testcase: usage-jshon-nested-key-list
# @title: jshon nested key list
# @description: Exercises jshon nested key list through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-nested-key-list"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

json='{"name":"demo","count":7,"ratio":1.5,"items":[1,2,3],"records":[{"name":"alpha"},{"name":"beta"}],"nested":{"empty":[],"child":{"label":"ok"}}}'
run_jshon() {
  printf '%s' "$1" | jshon "${@:2}" >"$tmpdir/out"
}

run_jshon "$json" -e nested -k
validator_assert_contains "$tmpdir/out" 'child'
validator_assert_contains "$tmpdir/out" 'empty'
