#!/usr/bin/env bash
# @testcase: usage-jshon-r15-across-mixed-types-prints-types-per-line
# @title: jshon -a -t prints the JSON type of each element of a mixed array
# @description: Pipes a six-element mixed-type array through jshon -a -t and verifies stdout contains the documented type names number, string, bool, null, array, object exactly in that order, one per line, exercising the across operator combined with type extraction.
# @timeout: 30
# @tags: usage, json, cli, across, type
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf '[1,"x",true,null,[1],{"k":1}]' | jshon -a -t >"$tmpdir/out"
cat >"$tmpdir/expected" <<'EOF'
number
string
bool
null
array
object
EOF
diff -u "$tmpdir/expected" "$tmpdir/out"
