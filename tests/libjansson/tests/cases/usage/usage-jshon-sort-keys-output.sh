#!/usr/bin/env bash
# @testcase: usage-jshon-sort-keys-output
# @title: jshon -S sorts object keys in output
# @description: Re-emits a JSON object through jshon -S and verifies the listed keys are produced in lexicographic order regardless of the input ordering.
# @timeout: 120
# @tags: usage, json
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-sort-keys-output"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Deliberately scrambled input order.
json='{"charlie":3,"alpha":1,"echo":5,"bravo":2,"delta":4}'

# Emit JSON sorted by keys, then list keys of the resulting document.
printf '%s' "$json" | jshon -S >"$tmpdir/sorted.json"
jshon -F "$tmpdir/sorted.json" -k >"$tmpdir/keys"

# Build the expected sorted-key listing.
cat >"$tmpdir/expected" <<'EOF'
alpha
bravo
charlie
delta
echo
EOF

if ! diff -u "$tmpdir/expected" "$tmpdir/keys" >"$tmpdir/diff"; then
  printf 'sorted key listing mismatch:\n' >&2
  cat "$tmpdir/diff" >&2
  exit 1
fi
