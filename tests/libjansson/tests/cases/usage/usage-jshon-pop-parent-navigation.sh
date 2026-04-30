#!/usr/bin/env bash
# @testcase: usage-jshon-pop-parent-navigation
# @title: jshon pop returns to parent context
# @description: Descends into a nested object with -e then uses -p to pop back and lists parent keys, verifying the keys belong to the outer object rather than the inner one.
# @timeout: 120
# @tags: usage, json
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-pop-parent-navigation"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

json='{"outer1":{"inner_a":1,"inner_b":2},"outer2":42,"outer3":"hi"}'

# Descend into outer1, then pop, then list keys: should be the outer keys.
printf '%s' "$json" | jshon -e outer1 -p -k >"$tmpdir/keys"

count=$(wc -l <"$tmpdir/keys")
if [[ "$count" -ne 3 ]]; then
  printf 'expected 3 outer keys after pop, got %s:\n' "$count" >&2
  cat "$tmpdir/keys" >&2
  exit 1
fi

for key in outer1 outer2 outer3; do
  if ! grep -Fxq -- "$key" "$tmpdir/keys"; then
    printf 'expected outer key %s after pop, got:\n' "$key" >&2
    cat "$tmpdir/keys" >&2
    exit 1
  fi
done

# Inner keys must NOT appear.
for inner in inner_a inner_b; do
  if grep -Fxq -- "$inner" "$tmpdir/keys"; then
    printf 'unexpected inner key %s after pop, got:\n' "$inner" >&2
    cat "$tmpdir/keys" >&2
    exit 1
  fi
done
