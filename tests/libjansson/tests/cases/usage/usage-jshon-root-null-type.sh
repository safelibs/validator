#!/usr/bin/env bash
# @testcase: usage-jshon-root-null-type
# @title: jshon rejects root null document
# @description: Runs jshon against a root null document and verifies the client rejects primitive-root JSON input.
# @timeout: 180
# @tags: usage, json
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-root-null-type"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

run_jshon() {
  printf '%s' "$1" | jshon "${@:2}" >"$tmpdir/out"
}

if printf 'null' | jshon -t >"$tmpdir/out" 2>&1; then
  printf 'jshon unexpectedly accepted a root null document\n' >&2
  exit 1
fi
validator_assert_contains "$tmpdir/out" "'[' or '{' expected"
validator_assert_contains "$tmpdir/out" "near 'null'"
