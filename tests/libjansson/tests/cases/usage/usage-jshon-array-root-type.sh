#!/usr/bin/env bash
# @testcase: usage-jshon-array-root-type
# @title: jshon root array type
# @description: Exercises jshon array root type through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-array-root-type"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

json='{"name":"demo","count":7,"ratio":1.5,"items":[1,2,3],"records":[{"name":"alpha"},{"name":"beta"}],"nested":{"empty":[],"child":{"label":"ok"}}}'
run_jshon() {
  printf '%s' "$1" | jshon "${@:2}" >"$tmpdir/out"
}

printf '[{"name":"alpha"}]' | jshon -t >"$tmpdir/out"
grep -Fxq 'array' "$tmpdir/out"
