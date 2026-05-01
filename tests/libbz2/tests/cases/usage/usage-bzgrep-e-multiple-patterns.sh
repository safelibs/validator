#!/usr/bin/env bash
# @testcase: usage-bzgrep-e-multiple-patterns
# @title: bzgrep -E alternation matches either pattern
# @description: Uses bzgrep -E with a regex alternation over a compressed file and verifies lines matching either pattern are emitted in original order regardless of alternation argument order.
# @timeout: 180
# @tags: usage, bzgrep, multi-pattern
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.txt" <<'EOF'
apple
banana
cherry
date
elderberry
fig
grape
EOF

bzip2 -c "$tmpdir/in.txt" >"$tmpdir/in.txt.bz2"

# bzgrep -E with alternation must OR the two patterns.
bzgrep -E '^(banana|fig)$' "$tmpdir/in.txt.bz2" >"$tmpdir/out"

printf 'banana\nfig\n' >"$tmpdir/expected"
cmp "$tmpdir/out" "$tmpdir/expected"

# Reversing the alternation order must not change which lines match.
bzgrep -E '^(fig|banana)$' "$tmpdir/in.txt.bz2" >"$tmpdir/out2"
cmp "$tmpdir/out2" "$tmpdir/expected"
