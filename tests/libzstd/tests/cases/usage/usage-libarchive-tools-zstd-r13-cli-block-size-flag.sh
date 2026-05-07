#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r13-cli-block-size-flag
# @title: zstd CLI -B131072 selects job size and still produces a valid roundtrippable frame
# @description: Compresses a 512KB payload with zstd -B131072 to set a 128KB job/block size, asserts the resulting .zst carries the standard zstd magic, passes -t integrity, and decompresses byte-for-byte to the source SHA-256.
# @timeout: 120
# @tags: usage, archive, zstd, cli, block-size
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/payload.bin"
python3 -c 'import sys
sys.stdout.buffer.write(b"r13 block-size payload row\n" * 20000)' >"$src"
validator_require_file "$src"
src_sum=$(sha256sum "$src" | awk '{print $1}')

zstd -q -B131072 -o "$tmpdir/out.zst" "$src"
validator_require_file "$tmpdir/out.zst"

magic=$(od -An -N4 -tx1 "$tmpdir/out.zst" | tr -d ' \n')
test "$magic" = "28b52ffd"

zstd -tq "$tmpdir/out.zst"
zstd -dq -c "$tmpdir/out.zst" >"$tmpdir/decoded.bin"
dst_sum=$(sha256sum "$tmpdir/decoded.bin" | awk '{print $1}')
test "$src_sum" = "$dst_sum"
