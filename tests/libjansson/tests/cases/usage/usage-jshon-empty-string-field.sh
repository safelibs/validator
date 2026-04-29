#!/usr/bin/env bash
# @testcase: usage-jshon-empty-string-field
# @title: jshon empty string field
# @description: Reads an empty string field with jshon and verifies that the unquoted output is empty.
# @timeout: 180
# @tags: usage, json, jshon
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-empty-string-field"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

run_jshon() {
  printf '%s' "$1" | jshon "${@:2}" >"$tmpdir/out"
}

run_jshon '{"label":""}' -e label -u
tr -d '\n' <"$tmpdir/out" >"$tmpdir/stripped"
test ! -s "$tmpdir/stripped"
