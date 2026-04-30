#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-cli-ultra-level-22
# @title: zstd CLI --ultra unlocks level 22
# @description: Compresses a payload with the standalone zstd CLI at the maximum level via --ultra -22, asserts the resulting frame carries the zstd magic, passes -t, and round-trips byte-for-byte to the original input.
# @timeout: 600
# @tags: usage, archive, zstd, cli
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/payload.bin"
python3 -c 'import sys
sys.stdout.buffer.write(b"ultra-level payload chunk\n" * 4096)' >"$src"
validator_require_file "$src"
src_sum=$(sha256sum "$src" | awk '{print $1}')

# Levels 20-22 require --ultra to unlock.
zstd -q --ultra -22 -o "$tmpdir/u.zst" "$src"
validator_require_file "$tmpdir/u.zst"

magic=$(od -An -N4 -tx1 "$tmpdir/u.zst" | tr -d ' \n')
test "$magic" = "28b52ffd"

zstd -tq "$tmpdir/u.zst"
zstd -dq -c "$tmpdir/u.zst" >"$tmpdir/decoded.bin"
cmp "$src" "$tmpdir/decoded.bin"

dst_sum=$(sha256sum "$tmpdir/decoded.bin" | awk '{print $1}')
test "$src_sum" = "$dst_sum"

# Output should be smaller than the source on a highly repetitive payload.
src_size=$(stat -c %s "$src")
zst_size=$(stat -c %s "$tmpdir/u.zst")
test "$zst_size" -lt "$src_size"
