#!/usr/bin/env bash
# @testcase: usage-jshon-r8-stdin-via-heredoc
# @title: jshon -F /dev/stdin reads document delivered through a here-document
# @description: Feeds a small object document through a quoted bash here-document into jshon -F /dev/stdin and confirms the parser accepts the synthetic stdin path, returning the expected top-level type, the deep-nested null type label, and the unstring of a string field, exercising the file-mode reader against a non-regular input.
# @timeout: 120
# @tags: usage, json, jshon
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-r8-stdin-via-heredoc"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Top-level type via -F /dev/stdin and a here-document.
jshon -F /dev/stdin -t >"$tmpdir/top-type" <<'EOF'
{"label":"hi","flags":[true,false,null]}
EOF
grep -Fxq -- 'object' "$tmpdir/top-type" || {
  printf 'expected top-level object via heredoc, got:\n' >&2
  cat "$tmpdir/top-type" >&2
  exit 1
}

# Nested null inside the array still types as null.
jshon -F /dev/stdin -e flags -e 2 -t >"$tmpdir/null-type" <<'EOF'
{"label":"hi","flags":[true,false,null]}
EOF
grep -Fxq -- 'null' "$tmpdir/null-type" || {
  printf 'expected nested null type via heredoc, got:\n' >&2
  cat "$tmpdir/null-type" >&2
  exit 1
}

# String field round-trips through unstring under -F /dev/stdin.
jshon -F /dev/stdin -e label -u >"$tmpdir/label" <<'EOF'
{"label":"hi","flags":[true,false,null]}
EOF
grep -Fxq -- 'hi' "$tmpdir/label" || {
  printf 'expected unstring hi via heredoc, got:\n' >&2
  cat "$tmpdir/label" >&2
  exit 1
}
