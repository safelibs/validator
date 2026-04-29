#!/usr/bin/env bash
# @testcase: usage-jshon-null-root-field-type
# @title: jshon null type
# @description: Reads a null field with jshon and verifies the selected value reports the null type.
# @timeout: 180
# @tags: usage, json, jshon
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-null-root-field-type"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

run_jshon() {
  printf '%s' "$1" | jshon "${@:2}" >"$tmpdir/out"
}

run_jshon '{"missing":null}' -e missing -t
validator_assert_contains "$tmpdir/out" 'null'
