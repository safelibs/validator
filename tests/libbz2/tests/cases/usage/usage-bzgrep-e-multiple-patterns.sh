#!/usr/bin/env bash
# @testcase: usage-bzgrep-e-multiple-patterns
# @title: bzgrep -e composes multiple patterns
# @description: Uses bzgrep -e PAT -e PAT to OR two distinct patterns over a compressed file and verifies lines matching either pattern are emitted in original order.
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

# bzgrep with two -e patterns must OR them.
bzgrep -e '^banana$' -e '^fig$' "$tmpdir/in.txt.bz2" >"$tmpdir/out"

printf 'banana\nfig\n' >"$tmpdir/expected"
cmp "$tmpdir/out" "$tmpdir/expected"

# Order-of-arguments must not change which lines match.
bzgrep -e '^fig$' -e '^banana$' "$tmpdir/in.txt.bz2" >"$tmpdir/out2"
cmp "$tmpdir/out2" "$tmpdir/expected"
