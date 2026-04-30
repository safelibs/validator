#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-cli-test-integrity-flag
# @title: zstd CLI -t test integrity on a valid file
# @description: Compresses a payload with the zstd CLI, then verifies the resulting frame passes the zstd -t (test) integrity check while a deliberately corrupted copy fails the same check.
# @timeout: 120
# @tags: usage, archive, zstd, cli
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/payload.txt"
printf 'integrity-flag payload\n' >"$src"

zstd -q -o "$tmpdir/good.zst" "$src"
validator_require_file "$tmpdir/good.zst"

magic=$(od -An -N4 -tx1 "$tmpdir/good.zst" | tr -d ' \n')
test "$magic" = "28b52ffd"

# A valid frame passes -t.
zstd -tq "$tmpdir/good.zst"

# Corrupting a byte well inside the frame (past the magic + frame header)
# must cause -t to report a non-zero exit.
cp "$tmpdir/good.zst" "$tmpdir/bad.zst"
size=$(stat -c %s "$tmpdir/bad.zst")
test "$size" -gt 12
# Flip one byte mid-frame using dd; bs=1 keeps it portable.
printf '\xff' | dd of="$tmpdir/bad.zst" bs=1 seek=10 count=1 conv=notrunc status=none

set +e
zstd -tq "$tmpdir/bad.zst" >/dev/null 2>&1
rc=$?
set -e
test "$rc" -ne 0
