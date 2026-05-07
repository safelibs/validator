#!/usr/bin/env bash
# @testcase: usage-jshon-r14-array-of-numbers-across-types-all-number
# @title: jshon -a -t on a homogeneous integer array yields four "number" lines
# @description: Pipes a 4-element integer array through jshon -a -t and verifies stdout contains exactly four lines each equal to the literal "number", exercising the across-iterator paired with type printing on a homogeneous numeric array.
# @timeout: 30
# @tags: usage, json, cli, iter
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf '[10,20,30,40]' | jshon -a -t >"$tmpdir/types"
cat >"$tmpdir/expected" <<'EOF'
number
number
number
number
EOF
diff -u "$tmpdir/expected" "$tmpdir/types"
