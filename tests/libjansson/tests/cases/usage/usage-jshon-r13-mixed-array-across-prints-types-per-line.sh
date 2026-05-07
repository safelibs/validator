#!/usr/bin/env bash
# @testcase: usage-jshon-r13-mixed-array-across-prints-types-per-line
# @title: jshon -a -t emits a per-element type line for a mixed-type array
# @description: Pipes a 4-element array containing one of each scalar shape (string, number, boolean, null) through jshon -a -t and verifies stdout contains exactly the four lines "string", "number", "bool", "null" in order, exercising iteration plus type printing.
# @timeout: 30
# @tags: usage, json, cli, iter
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf '["s",42,true,null]' | jshon -a -t >"$tmpdir/types"
cat >"$tmpdir/expected" <<'EOF'
string
number
bool
null
EOF
diff -u "$tmpdir/expected" "$tmpdir/types"
