#!/usr/bin/env bash
# @testcase: usage-jshon-r12-keys-after-insert-includes-new
# @title: jshon -k after -s value -i adds the new key to the listing
# @description: Inserts a string value into an object via -s value -i newkey and verifies jshon -k afterwards lists the new key alongside the original keys.
# @timeout: 30
# @tags: usage, json, cli, keys
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

result=$(printf '{"a":1,"b":2}' | jshon -s "z" -i c)
printf '%s' "$result" | jshon -k | sort >"$tmpdir/keys"
cat >"$tmpdir/expected" <<'EOF'
a
b
c
EOF
diff -u "$tmpdir/expected" "$tmpdir/keys"
