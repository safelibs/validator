#!/usr/bin/env bash
# @testcase: usage-jshon-r17-string-wrap-then-unwrap-roundtrip
# @title: jshon -s wrap of text then -u unwrap yields the original text
# @description: Wraps the literal text "round17" into a JSON string with jshon -s and immediately unwraps it through jshon -u, asserting the two-stage pipeline reconstructs the exact original ASCII payload, exercising libjansson's JSON string serialiser and parser round-trip.
# @timeout: 30
# @tags: usage, json, cli, string, roundtrip
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

wrapped=$(jshon -s round17 </dev/null)
[[ "$wrapped" == '"round17"' ]] || {
  printf 'expected "round17", got %s\n' "$wrapped" >&2
  exit 1
}

out=$(printf '%s' "$wrapped" | jshon -u)
if [[ "$out" != 'round17' ]]; then
  printf 'expected round17 after roundtrip, got %s\n' "$out" >&2
  exit 1
fi
