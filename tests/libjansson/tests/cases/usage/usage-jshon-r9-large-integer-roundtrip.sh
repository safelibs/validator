#!/usr/bin/env bash
# @testcase: usage-jshon-r9-large-integer-roundtrip
# @title: jshon preserves large positive integer
# @description: Reads a JSON document containing a 10-digit positive integer and verifies jshon -u emits the same integer literal.
# @timeout: 60
# @tags: usage, json, number
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

json='{"n":1234567890}'
printf '%s' "$json" | jshon -e n -u >"$tmpdir/out"
got=$(cat "$tmpdir/out")
[[ "$got" == "1234567890" ]] || {
  printf 'expected 1234567890, got %s\n' "$got" >&2
  exit 1
}

# Check the type as well.
printf '%s' "$json" | jshon -e n -t >"$tmpdir/t"
got=$(cat "$tmpdir/t")
[[ "$got" == "number" ]]
