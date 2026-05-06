#!/usr/bin/env bash
# @testcase: usage-jshon-r9-keys-sorted-by-input
# @title: jshon -k preserves input key order
# @description: Builds an object whose keys are inserted in non-alphabetical order and verifies jshon -k emits them in input insertion order.
# @timeout: 60
# @tags: usage, json, keys
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

json='{"zeta":1,"alpha":2,"mu":3,"beta":4}'

printf '%s' "$json" | jshon -k >"$tmpdir/keys"
expected=$'zeta\nalpha\nmu\nbeta'
got=$(cat "$tmpdir/keys")
[[ "$got" == "$expected" ]] || {
  printf 'expected %s, got %s\n' "$expected" "$got" >&2
  exit 1
}
