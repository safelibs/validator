#!/usr/bin/env bash
# @testcase: usage-jshon-file-array-sum
# @title: jshon file array sum
# @description: Exercises jshon file array sum through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-file-array-sum"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

json='{"name":"demo","count":7,"ratio":1.5,"items":[1,2,3],"records":[{"name":"alpha"},{"name":"beta"}],"nested":{"empty":[],"child":{"label":"ok"}}}'
run_jshon() {
  printf '%s' "$1" | jshon "${@:2}" >"$tmpdir/out"
}

printf '%s' "$json" >"$tmpdir/input.json"
jshon -F "$tmpdir/input.json" -e items -a -u >"$tmpdir/out"
awk '{sum += $1} END {print sum}' "$tmpdir/out" >"$tmpdir/sum"
grep -Fxq '6' "$tmpdir/sum"
