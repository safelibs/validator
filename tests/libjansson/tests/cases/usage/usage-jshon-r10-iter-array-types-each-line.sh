#!/usr/bin/env bash
# @testcase: usage-jshon-r10-iter-array-types-each-line
# @title: jshon -a -t emits one type per array element
# @description: Iterates a heterogeneous array via jshon -a and applies -t to each element, verifying every element-level type appears on its own output line.
# @timeout: 120
# @tags: usage, json, cli
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

json='[1,"two",true,null,{"k":1},[2,3]]'
printf '%s' "$json" | jshon -a -t >"$tmpdir/types"

cat >"$tmpdir/expected" <<'EOF'
number
string
bool
null
object
array
EOF

if ! diff -u "$tmpdir/expected" "$tmpdir/types" >"$tmpdir/diff"; then
  printf 'unexpected per-element type listing:\n' >&2
  cat "$tmpdir/diff" >&2
  exit 1
fi
