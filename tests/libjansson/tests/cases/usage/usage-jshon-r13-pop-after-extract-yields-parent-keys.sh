#!/usr/bin/env bash
# @testcase: usage-jshon-r13-pop-after-extract-yields-parent-keys
# @title: jshon -e child -p -k at a nested object lists the parent keys
# @description: Reads a parent object with two keys (one of which is itself an object), extracts the nested child, pops back with -p, and verifies -k afterwards lists exactly the original parent keys.
# @timeout: 30
# @tags: usage, json, cli, pop
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf '{"alpha":1,"nested":{"x":2}}' >"$tmpdir/in.json"
jshon -e nested -p -k <"$tmpdir/in.json" | sort >"$tmpdir/keys"
cat >"$tmpdir/expected" <<'EOF'
alpha
nested
EOF
diff -u "$tmpdir/expected" "$tmpdir/keys"
