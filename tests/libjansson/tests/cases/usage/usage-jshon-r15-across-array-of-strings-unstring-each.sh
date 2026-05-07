#!/usr/bin/env bash
# @testcase: usage-jshon-r15-across-array-of-strings-unstring-each
# @title: jshon -a -u unstrings every element of a string array onto its own line
# @description: Pipes a four-element string array through jshon -a -u and verifies stdout contains exactly the four raw values "alpha", "beta", "gamma", "delta" in order with no surrounding quotes, exercising the documented across operator combined with unstring.
# @timeout: 30
# @tags: usage, json, cli, across
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf '["alpha","beta","gamma","delta"]' | jshon -a -u >"$tmpdir/out"
cat >"$tmpdir/expected" <<'EOF'
alpha
beta
gamma
delta
EOF
diff -u "$tmpdir/expected" "$tmpdir/out"
