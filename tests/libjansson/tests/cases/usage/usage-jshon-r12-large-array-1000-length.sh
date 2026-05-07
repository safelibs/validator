#!/usr/bin/env bash
# @testcase: usage-jshon-r12-large-array-1000-length
# @title: jshon -l reports 1000 for a 1000-element integer array
# @description: Generates a JSON array of 1000 integers, pipes it into jshon -l and verifies the reported length is exactly 1000, exercising the parser at moderate scale.
# @timeout: 60
# @tags: usage, json, cli, scale
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

{
  printf '['
  for i in $(seq 1 999); do printf '%d,' "$i"; done
  printf '1000]'
} >"$tmpdir/big.json"

got=$(jshon -l <"$tmpdir/big.json")
[[ "$got" == "1000" ]] || { printf 'expected 1000, got %s\n' "$got" >&2; exit 1; }
