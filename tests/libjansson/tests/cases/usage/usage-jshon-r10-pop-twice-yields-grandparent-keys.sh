#!/usr/bin/env bash
# @testcase: usage-jshon-r10-pop-twice-yields-grandparent-keys
# @title: jshon -p applied twice ascends to the grandparent
# @description: Descends two levels into a nested object then issues two consecutive -p operations and lists keys, verifying the result lists the grandparent (root) keys rather than either intermediate scope.
# @timeout: 60
# @tags: usage, json, cli
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

json='{"root_a":{"middle":{"leaf":42}},"root_b":1,"root_c":2}'
printf '%s' "$json" | jshon -e root_a -e middle -p -p -k >"$tmpdir/keys"

count=$(wc -l <"$tmpdir/keys")
if [[ "$count" -ne 3 ]]; then
  printf 'expected 3 root keys after two pops, got %s:\n' "$count" >&2
  cat "$tmpdir/keys" >&2
  exit 1
fi

for key in root_a root_b root_c; do
  if ! grep -Fxq -- "$key" "$tmpdir/keys"; then
    printf 'missing root key %s in pop-pop output:\n' "$key" >&2
    cat "$tmpdir/keys" >&2
    exit 1
  fi
done

for key in middle leaf; do
  if grep -Fxq -- "$key" "$tmpdir/keys"; then
    printf 'unexpected nested key %s after two pops:\n' "$key" >&2
    cat "$tmpdir/keys" >&2
    exit 1
  fi
done
