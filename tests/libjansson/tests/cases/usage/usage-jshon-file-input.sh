#!/usr/bin/env bash
# @testcase: usage-jshon-file-input
# @title: jshon reads file input
# @description: Loads JSON from a file path and extracts a stored member.
# @timeout: 120
# @tags: usage, json
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-file-input"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

json='{"name":"demo","count":7,"active":true,"items":[1,2,3],"nested":{"value":"ok"}}'

run_jshon() {
  printf '%s' "$1" | jshon "${@:2}" >"$tmpdir/out"
}

printf '%s' "$json" >"$tmpdir/input.json"
jshon -F "$tmpdir/input.json" -e name -u >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'demo'
