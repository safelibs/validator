#!/usr/bin/env bash
# @testcase: usage-jshon-unicode-escape-string
# @title: jshon Unicode escape string
# @description: Decodes a Unicode escape sequence with jshon and verifies the resulting text value.
# @timeout: 180
# @tags: usage, json, jshon
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-unicode-escape-string"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

run_jshon() {
  printf '%s' "$1" | jshon "${@:2}" >"$tmpdir/out"
}

run_jshon '{"word":"caf\u00e9"}' -e word -u
od -An -tx1 "$tmpdir/out" >"$tmpdir/hex"
validator_assert_contains "$tmpdir/hex" '63 61 66 c3 a9'
