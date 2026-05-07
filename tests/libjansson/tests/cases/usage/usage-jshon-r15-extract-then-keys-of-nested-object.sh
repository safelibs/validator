#!/usr/bin/env bash
# @testcase: usage-jshon-r15-extract-then-keys-of-nested-object
# @title: jshon -e nested -k lists the keys of a nested object
# @description: Pipes an object with a nested object under key "nested" through jshon -e nested -k and verifies stdout contains exactly the three nested keys "x", "y", "z" in source order, exercising extract followed by key enumeration.
# @timeout: 30
# @tags: usage, json, cli, keys
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf '{"nested":{"x":1,"y":2,"z":3}}' | jshon -e nested -k >"$tmpdir/keys"
cat >"$tmpdir/expected" <<'EOF'
x
y
z
EOF
diff -u "$tmpdir/expected" "$tmpdir/keys"
