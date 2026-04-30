#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-cli-memory-limit-decode
# @title: zstd CLI --memory=64MB decode memlimit
# @description: Compresses a small payload with the zstd CLI, then decompresses it with --memory=64MB to set the decoder memory budget well above the frame's window requirement, asserting the decoded bytes match the original byte-for-byte.
# @timeout: 120
# @tags: usage, archive, zstd, cli
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/payload.bin"
python3 -c 'import sys
sys.stdout.buffer.write(b"memlimit payload segment\n" * 1024)' >"$src"
validator_require_file "$src"
src_sum=$(sha256sum "$src" | awk '{print $1}')

zstd -q -o "$tmpdir/out.zst" "$src"
validator_require_file "$tmpdir/out.zst"

magic=$(od -An -N4 -tx1 "$tmpdir/out.zst" | tr -d ' \n')
test "$magic" = "28b52ffd"

# --memory=64MB caps the decoder's memory budget; the small frame above
# fits well under that ceiling so decompression must succeed cleanly.
zstd -dq --memory=64MB -c "$tmpdir/out.zst" >"$tmpdir/decoded.bin"
cmp "$src" "$tmpdir/decoded.bin"
dst_sum=$(sha256sum "$tmpdir/decoded.bin" | awk '{print $1}')
test "$src_sum" = "$dst_sum"
