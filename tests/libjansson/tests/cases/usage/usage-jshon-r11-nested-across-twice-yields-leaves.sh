#!/usr/bin/env bash
# @testcase: usage-jshon-r11-nested-across-twice-yields-leaves
# @title: jshon -a -a -u maps unstring across leaves of a 2D array
# @description: Iterates a 2x2 numeric matrix with two -a actions and -u, verifying the result is one leaf value per line in row-major order, exercising nested -a behavior.
# @timeout: 60
# @tags: usage, json, cli, across
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf '[[10,20],[30,40]]' | jshon -a -a -u >"$tmpdir/leaves"

cat >"$tmpdir/expected" <<'EOF'
10
20
30
40
EOF

if ! diff -u "$tmpdir/expected" "$tmpdir/leaves" >"$tmpdir/diff"; then
    printf 'unexpected leaf order:\n' >&2
    cat "$tmpdir/diff" >&2
    exit 1
fi
