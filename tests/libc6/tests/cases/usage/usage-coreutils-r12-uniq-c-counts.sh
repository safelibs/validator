#!/usr/bin/env bash
# @testcase: usage-coreutils-r12-uniq-c-counts
# @title: coreutils uniq -c emits adjacent run lengths
# @description: Feeds a sorted file with duplicate adjacent lines through uniq -c and verifies the leading count column matches the expected run lengths for each distinct line.
# @timeout: 60
# @tags: usage, coreutils, uniq
# @client: coreutils

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.txt" <<'EOF'
apple
apple
apple
banana
cherry
cherry
EOF

LC_ALL=C uniq -c "$tmpdir/in.txt" | LC_ALL=C awk '{$1=$1; print}' >"$tmpdir/got.txt"

cat >"$tmpdir/expected.txt" <<'EOF'
3 apple
1 banana
2 cherry
EOF

cmp "$tmpdir/got.txt" "$tmpdir/expected.txt"
