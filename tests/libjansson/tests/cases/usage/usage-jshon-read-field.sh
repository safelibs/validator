#!/usr/bin/env bash
# @testcase: usage-jshon-read-field
# @title: jshon reads a string field
# @description: Extracts a string member from an object with jshon.
# @timeout: 120
# @tags: usage, json
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-read-field"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

json='{"name":"demo","count":7,"active":true,"items":[1,2,3],"nested":{"value":"ok"}}'

run_jshon() {
  printf '%s' "$1" | jshon "${@:2}" >"$tmpdir/out"
}

run_jshon "$json" -e name -u
validator_assert_contains "$tmpdir/out" 'demo'
