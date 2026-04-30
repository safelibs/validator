#!/usr/bin/env bash
# @testcase: usage-jshon-delete-key-roundtrip
# @title: jshon delete key roundtrip
# @description: Removes an object member with -d and confirms that key is absent from the keys listing while siblings remain.
# @timeout: 120
# @tags: usage, json
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-delete-key-roundtrip"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

json='{"alpha":1,"beta":2,"gamma":3}'

# Delete "beta" then list keys of the resulting object.
printf '%s' "$json" | jshon -d beta -k >"$tmpdir/keys"

if grep -Fxq -- 'beta' "$tmpdir/keys"; then
  printf 'expected beta to be deleted, got keys:\n' >&2
  cat "$tmpdir/keys" >&2
  exit 1
fi

for key in alpha gamma; do
  if ! grep -Fxq -- "$key" "$tmpdir/keys"; then
    printf 'expected key %s to remain after delete, got:\n' "$key" >&2
    cat "$tmpdir/keys" >&2
    exit 1
  fi
done

count=$(wc -l <"$tmpdir/keys")
if [[ "$count" -ne 2 ]]; then
  printf 'expected 2 remaining keys, got %s\n' "$count" >&2
  cat "$tmpdir/keys" >&2
  exit 1
fi
