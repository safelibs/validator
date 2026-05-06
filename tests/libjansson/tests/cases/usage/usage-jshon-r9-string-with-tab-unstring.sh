#!/usr/bin/env bash
# @testcase: usage-jshon-r9-string-with-tab-unstring
# @title: jshon -u preserves embedded tab in string
# @description: Extracts a string field containing an embedded tab via -u and verifies the rendered output contains an actual tab character.
# @timeout: 60
# @tags: usage, json, string
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

json='{"v":"a\tb"}'

printf '%s' "$json" | jshon -e v -u >"$tmpdir/out"
# Output should be exactly "a<TAB>b" possibly with trailing newline.
expected=$'a\tb'
got=$(cat "$tmpdir/out")
[[ "$got" == "$expected" ]] || {
  printf 'expected tab-separated, got %q\n' "$got" >&2
  exit 1
}
