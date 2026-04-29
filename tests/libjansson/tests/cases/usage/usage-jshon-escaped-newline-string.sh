#!/usr/bin/env bash
# @testcase: usage-jshon-escaped-newline-string
# @title: jshon escaped newline string
# @description: Decodes an escaped newline string with jshon and verifies both decoded text lines are present in the output.
# @timeout: 180
# @tags: usage, json, jshon
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-escaped-newline-string"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

run_jshon() {
  printf '%s' "$1" | jshon "${@:2}" >"$tmpdir/out"
}

run_jshon '{"text":"alpha\nbeta"}' -e text -u
validator_assert_contains "$tmpdir/out" 'alpha'
validator_assert_contains "$tmpdir/out" 'beta'
