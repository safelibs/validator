#!/usr/bin/env bash
# @testcase: usage-jshon-edit-extract-chain
# @title: jshon edit then extract chain
# @description: Deletes a key from a root object with -d, then extracts a sibling and unstrings its value within the same jshon invocation, asserting the chain produces the expected leaf and that the deleted key is absent from a follow-up keys listing.
# @timeout: 120
# @tags: usage, json
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-edit-extract-chain"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

json='{"keep_me":"hello-world","drop_me":123,"also_keep":"second"}'

# Single chained invocation: delete drop_me, extract keep_me, unstring.
printf '%s' "$json" | jshon -d drop_me -e keep_me -u >"$tmpdir/leaf"

if ! grep -Fxq -- 'hello-world' "$tmpdir/leaf"; then
  printf 'expected hello-world after edit-then-extract, got:\n' >&2
  cat "$tmpdir/leaf" >&2
  exit 1
fi

# Separate invocation to confirm drop_me was actually removed and others remain.
printf '%s' "$json" | jshon -d drop_me -k >"$tmpdir/keys"

count=$(wc -l <"$tmpdir/keys")
if [[ "$count" -ne 2 ]]; then
  printf 'expected 2 keys after delete, got %s:\n' "$count" >&2
  cat "$tmpdir/keys" >&2
  exit 1
fi

if grep -Fxq -- 'drop_me' "$tmpdir/keys"; then
  printf 'expected drop_me to be deleted, got:\n' >&2
  cat "$tmpdir/keys" >&2
  exit 1
fi

for key in keep_me also_keep; do
  if ! grep -Fxq -- "$key" "$tmpdir/keys"; then
    printf 'expected key %s to remain, got:\n' "$key" >&2
    cat "$tmpdir/keys" >&2
    exit 1
  fi
done
