#!/usr/bin/env bash
# @testcase: usage-jshon-r9-empty-array-aggregate-noop
# @title: jshon -a on empty array produces no output
# @description: Iterates an empty array via -a and verifies the resulting stream contains zero elements.
# @timeout: 60
# @tags: usage, json, array
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

json='{"items":[]}'
printf '%s' "$json" | jshon -e items -a -u >"$tmpdir/out" || true
# Expect empty file (0 lines).
n=$(wc -l <"$tmpdir/out")
[[ "$n" == "0" ]] || {
  printf 'expected 0 lines, got %s\n' "$n" >&2
  cat "$tmpdir/out" >&2
  exit 1
}
