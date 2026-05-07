#!/usr/bin/env bash
# @testcase: usage-jshon-r14-delete-object-key-removes-from-keys
# @title: jshon -d on an object key removes it from the -k listing
# @description: Pipes a three-key object through jshon -d middle and verifies the resulting -k listing contains exactly "first" and "last" (sorted), exercising the documented delete operator on object keys.
# @timeout: 30
# @tags: usage, json, cli, delete
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

result=$(printf '{"first":1,"middle":2,"last":3}' | jshon -d middle)
printf '%s' "$result" | jshon -k | sort >"$tmpdir/keys"
cat >"$tmpdir/expected" <<'EOF'
first
last
EOF
diff -u "$tmpdir/expected" "$tmpdir/keys"
