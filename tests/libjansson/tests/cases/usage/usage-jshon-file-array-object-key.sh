#!/usr/bin/env bash
# @testcase: usage-jshon-file-array-object-key
# @title: jshon file array object key
# @description: Traverses an object inside a JSON array loaded from file and verifies the selected field value.
# @timeout: 180
# @tags: usage, json
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-file-array-object-key"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

run_jshon() {
  printf '%s' "$1" | jshon "${@:2}" >"$tmpdir/out"
}

printf '[{"name":"alpha"},{"name":"beta"}]' >"$tmpdir/input.json"
jshon -F "$tmpdir/input.json" -e 1 -e name -u >"$tmpdir/out"
grep -Fxq 'beta' "$tmpdir/out"
