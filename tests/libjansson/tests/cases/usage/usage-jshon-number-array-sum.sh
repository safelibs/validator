#!/usr/bin/env bash
# @testcase: usage-jshon-number-array-sum
# @title: jshon number array values
# @description: Maps numeric array values with jshon and sums them in the shell.
# @timeout: 180
# @tags: usage, json
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-number-array-sum"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

json='{"name":"demo","count":7,"active":true,"disabled":false,"empty":null,"items":[1,2,3],"records":[{"name":"alpha"},{"name":"beta"}],"nested":{"value":"ok","label":"hello world"}}'
run_jshon() {
  printf '%s' "$1" | jshon "${@:2}" >"$tmpdir/out"
}

run_jshon "$json" -e items -a -u
awk '{sum += $1} END {print "sum=" sum}' "$tmpdir/out" >"$tmpdir/sum"
validator_assert_contains "$tmpdir/sum" 'sum=6'
