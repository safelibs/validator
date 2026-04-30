#!/usr/bin/env bash
# @testcase: usage-gzip-zgrep-regex
# @title: gzip zgrep matches regex inside compressed file
# @description: Compresses a fixed text fixture with gzip and uses zgrep to match a regular expression against it, verifying exact matching lines and count.
# @timeout: 180
# @tags: usage, gzip, compression
# @client: gzip

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gzip-zgrep-regex"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.txt" <<'EOF'
order-001 alpha
note: ignore this
order-002 beta
order-010 gamma
trailing line
EOF

gzip -c "$tmpdir/in.txt" >"$tmpdir/in.txt.gz"

# zgrep is part of the gzip package on Ubuntu and must invoke grep transparently.
zgrep -E '^order-[0-9]+ ' "$tmpdir/in.txt.gz" >"$tmpdir/out"

test "$(wc -l <"$tmpdir/out")" -eq 3
grep -Fxq 'order-001 alpha' "$tmpdir/out"
grep -Fxq 'order-002 beta' "$tmpdir/out"
grep -Fxq 'order-010 gamma' "$tmpdir/out"
! grep -q 'note:' "$tmpdir/out"
! grep -q 'trailing line' "$tmpdir/out"

# Cross-check via zcat to ensure compression itself round-trips.
zcat "$tmpdir/in.txt.gz" >"$tmpdir/decompressed"
cmp "$tmpdir/decompressed" "$tmpdir/in.txt"
