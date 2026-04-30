#!/usr/bin/env bash
# @testcase: usage-jshon-r5-keys-insertion-order
# @title: jshon -k preserves object insertion order
# @description: Constructs an object with a deliberately non-alphabetical insertion order and verifies that jshon -k emits the keys in that exact source order, line by line.
# @timeout: 120
# @tags: usage, json, jshon
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-r5-keys-insertion-order"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Deliberately non-alphabetical and non-numeric ordering.
json='{"zeta":1,"alpha":2,"mike":3,"bravo":4,"yankee":5}'

printf '%s' "$json" | jshon -k >"$tmpdir/keys"

cat >"$tmpdir/expected" <<'EOF'
zeta
alpha
mike
bravo
yankee
EOF

if ! diff -u "$tmpdir/expected" "$tmpdir/keys" >"$tmpdir/diff"; then
  printf 'expected jshon -k to preserve insertion order, diff:\n' >&2
  cat "$tmpdir/diff" >&2
  exit 1
fi
