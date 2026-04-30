#!/usr/bin/env bash
# @testcase: usage-jshon-keys-listing-multiple
# @title: jshon keys listing across object members
# @description: Lists object keys with -k and verifies every declared member name appears in the output.
# @timeout: 120
# @tags: usage, json
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-keys-listing-multiple"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

json='{"alpha":1,"beta":2,"gamma":3,"delta":4,"epsilon":5}'

printf '%s' "$json" | jshon -k >"$tmpdir/out"

for key in alpha beta gamma delta epsilon; do
  if ! grep -Fxq -- "$key" "$tmpdir/out"; then
    printf 'expected key %s in jshon -k output\n' "$key" >&2
    cat "$tmpdir/out" >&2
    exit 1
  fi
done

count=$(wc -l <"$tmpdir/out")
if [[ "$count" -ne 5 ]]; then
  printf 'expected 5 keys, got %s\n' "$count" >&2
  cat "$tmpdir/out" >&2
  exit 1
fi
