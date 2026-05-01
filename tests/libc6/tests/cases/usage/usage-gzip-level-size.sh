#!/usr/bin/env bash
# @testcase: usage-gzip-level-size
# @title: gzip -1 and -9 produce different sizes
# @description: Compresses identical input with gzip -1 (fast) and gzip -9 (best) and verifies both decompress back to the original payload while -9 produces output no larger than -1.
# @timeout: 180
# @tags: usage, gzip, libc
# @client: gzip

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gzip-level-size"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Build a sufficiently large, repetitive payload so the levels diverge.
payload="$tmpdir/payload.txt"
: >"$payload"
for _ in $(seq 1 200); do
  printf 'the quick brown fox jumps over the lazy dog 0123456789\n' >>"$payload"
done

original_size=$(stat -c '%s' "$payload")
test "$original_size" -gt 0

gzip -1 -c -n "$payload" >"$tmpdir/fast.gz"
gzip -9 -c -n "$payload" >"$tmpdir/best.gz"

fast_size=$(stat -c '%s' "$tmpdir/fast.gz")
best_size=$(stat -c '%s' "$tmpdir/best.gz")

test "$fast_size" -gt 0
test "$best_size" -gt 0
# -9 must be no larger than -1 on a compressible payload.
test "$best_size" -le "$fast_size"
# Both must produce real compression on this repetitive input.
test "$fast_size" -lt "$original_size"
test "$best_size" -lt "$original_size"

# Round-trip: both archives must decompress to the original bytes.
gunzip -c "$tmpdir/fast.gz" >"$tmpdir/fast.out"
gunzip -c "$tmpdir/best.gz" >"$tmpdir/best.out"
cmp "$payload" "$tmpdir/fast.out"
cmp "$payload" "$tmpdir/best.out"
