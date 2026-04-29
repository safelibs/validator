#!/usr/bin/env bash
# @testcase: usage-jshon-float-field
# @title: jshon float field
# @description: Exercises jshon float field through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-float-field"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

json='{"name":"demo","count":7,"ratio":1.5,"items":[1,2,3],"records":[{"name":"alpha"},{"name":"beta"}],"nested":{"empty":[],"child":{"label":"ok"}}}'
run_jshon() {
  printf '%s' "$1" | jshon "${@:2}" >"$tmpdir/out"
}

run_jshon "$json" -e ratio -u
grep -Fxq '1.5' "$tmpdir/out"
