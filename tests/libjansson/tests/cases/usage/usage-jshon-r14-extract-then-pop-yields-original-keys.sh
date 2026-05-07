#!/usr/bin/env bash
# @testcase: usage-jshon-r14-extract-then-pop-yields-original-keys
# @title: jshon -e a -p -k after extract and pop lists the root keys
# @description: Pipes a two-key root object through jshon -e a -p -k and verifies the popped context lists exactly the original root keys "a" and "b" (sorted), exercising the documented round-trip extract-then-pop navigation.
# @timeout: 30
# @tags: usage, json, cli, pop
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf '{"a":{"x":1},"b":{"y":2}}' >"$tmpdir/in.json"
jshon -e a -p -k <"$tmpdir/in.json" | sort >"$tmpdir/keys"
cat >"$tmpdir/expected" <<'EOF'
a
b
EOF
diff -u "$tmpdir/expected" "$tmpdir/keys"
