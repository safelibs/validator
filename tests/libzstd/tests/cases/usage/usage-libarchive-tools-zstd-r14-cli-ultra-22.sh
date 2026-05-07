#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r14-cli-ultra-22
# @title: zstd -22 --ultra accepts the maximum strategy level and the frame round-trips
# @description: Compresses a small payload at zstd -22 with --ultra (which unlocks levels 20-22), asserts the produced .zst carries the standard zstd frame magic, passes -t integrity, and decompresses byte-for-byte to the source SHA-256.
# @timeout: 180
# @tags: usage, archive, zstd, cli, ultra
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/payload.bin"
python3 -c 'import sys
sys.stdout.buffer.write(b"r14 ultra-22 payload row\n" * 2000)' >"$src"
src_sum=$(sha256sum "$src" | awk '{print $1}')

zstd -q -22 --ultra -o "$tmpdir/out.zst" "$src"
validator_require_file "$tmpdir/out.zst"

magic=$(od -An -N4 -tx1 "$tmpdir/out.zst" | tr -d ' \n')
test "$magic" = "28b52ffd"

zstd -tq "$tmpdir/out.zst"

zstd -dq -c "$tmpdir/out.zst" >"$tmpdir/decoded.bin"
dst_sum=$(sha256sum "$tmpdir/decoded.bin" | awk '{print $1}')
[[ "$src_sum" == "$dst_sum" ]] || {
    printf 'sha256 mismatch after -22 --ultra roundtrip\n' >&2
    exit 1
}
