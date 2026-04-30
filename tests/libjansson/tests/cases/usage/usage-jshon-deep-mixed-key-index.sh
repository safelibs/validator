#!/usr/bin/env bash
# @testcase: usage-jshon-deep-mixed-key-index
# @title: jshon deep extract with mixed object keys and array indices
# @description: Walks a four-level nested document by alternating object key extracts and array index extracts and verifies the leaf string value is reached intact.
# @timeout: 120
# @tags: usage, json
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-deep-mixed-key-index"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# root.users[1].profile.tags[2] == "deep-leaf"
cat >"$tmpdir/input.json" <<'EOF'
{
  "users": [
    {"profile": {"tags": ["x", "y", "z"]}},
    {"profile": {"tags": ["alpha", "beta", "deep-leaf", "delta"]}}
  ]
}
EOF

jshon -F "$tmpdir/input.json" -e users -e 1 -e profile -e tags -e 2 -u >"$tmpdir/leaf"

if ! grep -Fxq -- 'deep-leaf' "$tmpdir/leaf"; then
  printf 'expected deep-leaf at users[1].profile.tags[2], got:\n' >&2
  cat "$tmpdir/leaf" >&2
  exit 1
fi

# Type at the leaf must be string.
jshon -F "$tmpdir/input.json" -e users -e 1 -e profile -e tags -e 2 -t >"$tmpdir/type"
if ! grep -Fxq -- 'string' "$tmpdir/type"; then
  printf 'expected leaf type string, got:\n' >&2
  cat "$tmpdir/type" >&2
  exit 1
fi

# Length at users[1].profile.tags must be 4.
jshon -F "$tmpdir/input.json" -e users -e 1 -e profile -e tags -l >"$tmpdir/len"
if ! grep -Fxq -- '4' "$tmpdir/len"; then
  printf 'expected tags length 4, got:\n' >&2
  cat "$tmpdir/len" >&2
  exit 1
fi
