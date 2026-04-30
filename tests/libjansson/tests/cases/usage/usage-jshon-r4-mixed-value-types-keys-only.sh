#!/usr/bin/env bash
# @testcase: usage-jshon-r4-mixed-value-types-keys-only
# @title: jshon -k lists keys regardless of value type
# @description: Lists keys of an object whose values span all JSON scalar and container types and verifies jshon -k emits only the key names exactly once each, with no value bytes leaking into the listing.
# @timeout: 120
# @tags: usage, json, jshon
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-r4-mixed-value-types-keys-only"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

json='{"s":"text","n":42,"b":true,"z":null,"arr":[1,2],"obj":{"k":"v"}}'

printf '%s' "$json" | jshon -k >"$tmpdir/keys"

count=$(wc -l <"$tmpdir/keys")
if [[ "$count" -ne 6 ]]; then
  printf 'expected 6 key lines, got %s:\n' "$count" >&2
  cat "$tmpdir/keys" >&2
  exit 1
fi

for key in s n b z arr obj; do
  if ! grep -Fxq -- "$key" "$tmpdir/keys"; then
    printf 'expected key %s in listing, got:\n' "$key" >&2
    cat "$tmpdir/keys" >&2
    exit 1
  fi
done

# Value bytes must NOT appear in the keys output.
for noise in 'text' '42' 'true' 'null' '[1,2]' 'k'; do
  if grep -Fq -- "$noise" "$tmpdir/keys"; then
    printf 'unexpected value fragment %s in keys output:\n' "$noise" >&2
    cat "$tmpdir/keys" >&2
    exit 1
  fi
done
