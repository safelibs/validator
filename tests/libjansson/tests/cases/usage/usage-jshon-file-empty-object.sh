#!/usr/bin/env bash
# @testcase: usage-jshon-file-empty-object
# @title: jshon file empty object
# @description: Loads an empty object from a JSON file path with jshon and verifies the document type.
# @timeout: 180
# @tags: usage, json
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-file-empty-object"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

run_jshon() {
  printf '%s' "$1" | jshon "${@:2}" >"$tmpdir/out"
}

printf '{}' >"$tmpdir/input.json"
jshon -F "$tmpdir/input.json" -t >"$tmpdir/out"
grep -Fxq 'object' "$tmpdir/out"
