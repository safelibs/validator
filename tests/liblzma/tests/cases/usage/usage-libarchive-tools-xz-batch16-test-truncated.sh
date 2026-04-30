#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-batch16-test-truncated
# @title: xz -t fails on truncated stream
# @description: Truncates a valid .xz file mid-stream and confirms xz -t (test mode) rejects it with non-zero status, while a complete copy still verifies clean.
# @timeout: 180
# @tags: usage, xz, integrity
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Build a payload large enough that truncation lands inside the encoded body.
python3 -c 'import sys
for i in range(4096):
    sys.stdout.write(f"row {i:05d} truncation guard payload\n")' >"$tmpdir/data.bin"

xz -z -k -c "$tmpdir/data.bin" >"$tmpdir/data.xz"

# Sanity: full file passes xz -t.
xz -t "$tmpdir/data.xz"

# Truncate to roughly half its size.
full_size=$(stat -c %s "$tmpdir/data.xz")
half_size=$((full_size / 2))
test "$half_size" -gt 16
dd if="$tmpdir/data.xz" of="$tmpdir/trunc.xz" bs=1 count="$half_size" status=none

# xz -t must fail on the truncated stream.
set +e
xz -t "$tmpdir/trunc.xz" >"$tmpdir/test.out" 2>"$tmpdir/test.err"
rc=$?
set -e
test "$rc" -ne 0

# Sanity: original is still good.
xz -t "$tmpdir/data.xz"
