#!/usr/bin/env bash
# @testcase: usage-jshon-file-vs-stdin-equivalence
# @title: jshon file input matches stdin input
# @description: Runs the same query with -F and via stdin and verifies both produce identical output.
# @timeout: 120
# @tags: usage, json
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-file-vs-stdin-equivalence"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

json='{"name":"demo","count":7,"items":[1,2,3]}'
printf '%s' "$json" >"$tmpdir/input.json"

jshon -F "$tmpdir/input.json" -e items -l >"$tmpdir/file_out"
printf '%s' "$json" | jshon -e items -l >"$tmpdir/stdin_out"

if ! diff -u "$tmpdir/file_out" "$tmpdir/stdin_out" >"$tmpdir/diff"; then
  printf '-F vs stdin differ:\n' >&2
  cat "$tmpdir/diff" >&2
  exit 1
fi

validator_assert_contains "$tmpdir/file_out" '3'
