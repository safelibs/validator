#!/usr/bin/env bash
# @testcase: usage-jshon-r14-across-extract-id-from-array-of-objects
# @title: jshon -a -e id -u prints the id field from each object in an array
# @description: Pipes an array of three objects each carrying an "id" field through jshon -a -e id -u and verifies stdout contains exactly the three id values "1", "2", "3" in order, exercising the across operator combined with extraction.
# @timeout: 30
# @tags: usage, json, cli, across
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf '[{"id":1},{"id":2},{"id":3}]' | jshon -a -e id -u >"$tmpdir/ids"
cat >"$tmpdir/expected" <<'EOF'
1
2
3
EOF
diff -u "$tmpdir/expected" "$tmpdir/ids"
