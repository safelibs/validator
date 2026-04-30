#!/usr/bin/env bash
# @testcase: usage-jshon-deep-extract-unstring
# @title: jshon deep extract then unstring
# @description: Drills three levels into nested objects and arrays then prints the leaf value with -u stripped of quotes.
# @timeout: 120
# @tags: usage, json
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-deep-extract-unstring"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

json='{"a":{"b":{"c":[{"label":"deep-leaf"}]}}}'

printf '%s' "$json" | jshon -e a -e b -e c -e 0 -e label -u >"$tmpdir/out"
if ! grep -Fxq -- 'deep-leaf' "$tmpdir/out"; then
  printf 'expected deep-leaf, got:\n' >&2
  cat "$tmpdir/out" >&2
  exit 1
fi
