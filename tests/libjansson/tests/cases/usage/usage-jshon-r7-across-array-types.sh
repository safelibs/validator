#!/usr/bin/env bash
# @testcase: usage-jshon-r7-across-array-types
# @title: jshon -a iterates element types across an array
# @description: Applies jshon -a -t against a heterogeneous five-element root array and verifies that the across operator emits exactly five lines of type labels in array order, matching number, string, bool, null, and object respectively.
# @timeout: 120
# @tags: usage, json, jshon
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-r7-across-array-types"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

json='[1,"two",true,null,{"k":1}]'

printf '%s' "$json" | jshon -a -t >"$tmpdir/types"

count=$(wc -l <"$tmpdir/types")
if [[ "$count" -ne 5 ]]; then
  printf 'expected 5 type lines from -a -t, got %s:\n' "$count" >&2
  cat "$tmpdir/types" >&2
  exit 1
fi

expected=$(printf 'number\nstring\nbool\nnull\nobject\n')
if [[ "$(cat "$tmpdir/types")" != "$expected" ]]; then
  printf 'unexpected type sequence from -a -t, got:\n' >&2
  cat "$tmpdir/types" >&2
  exit 1
fi
