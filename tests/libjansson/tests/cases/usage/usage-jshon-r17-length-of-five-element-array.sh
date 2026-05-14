#!/usr/bin/env bash
# @testcase: usage-jshon-r17-length-of-five-element-array
# @title: jshon -l reports 5 for a five-element integer array
# @description: Builds a five-element integer array via jshon -n array followed by five -n N -i append steps and asserts jshon -l reports exactly "5", exercising libjansson's array length reflection (distinct from the r16 three-key object length test) using an array root.
# @timeout: 30
# @tags: usage, json, cli, length, array
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

arr=$(jshon -n array \
  -n 10 -i append \
  -n 20 -i append \
  -n 30 -i append \
  -n 40 -i append \
  -n 50 -i append)
printf '%s' "$arr" >"$tmpdir/arr.json"

len=$(jshon -F "$tmpdir/arr.json" -l)
if [[ "$len" != '5' ]]; then
  printf 'expected length 5, got %s\n' "$len" >&2
  exit 1
fi
