#!/usr/bin/env bash
# @testcase: usage-sed-r15-last-line-dollar-delete
# @title: sed '$d' deletes only the final line of input
# @description: Pipes a fixed four-line input through sed '$d' under LC_ALL=C and asserts the output is the first three lines verbatim — confirming sed's libc-backed line-buffer tracks the last-line ($) address.
# @timeout: 60
# @tags: usage, sed, address, r15
# @client: sed

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'one\ntwo\nthree\nlast\n' >"$tmpdir/in.txt"

LC_ALL=C sed '$d' "$tmpdir/in.txt" >"$tmpdir/got.txt"

cat >"$tmpdir/expected.txt" <<'EOF'
one
two
three
EOF

cmp "$tmpdir/got.txt" "$tmpdir/expected.txt"
