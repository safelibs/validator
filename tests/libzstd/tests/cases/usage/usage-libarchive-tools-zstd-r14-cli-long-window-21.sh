#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r14-cli-long-window-21
# @title: zstd --long=21 enables a 2 MiB window and the produced frame round-trips
# @description: Compresses a multi-megabyte payload with zstd --long=21 (2 MiB window log) so the long-distance matching path is exercised, asserts the resulting .zst carries the standard zstd frame magic, passes -t integrity, and decompresses back to a byte-identical SHA-256 of the source.
# @timeout: 180
# @tags: usage, archive, zstd, cli, long
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/payload.bin"
python3 -c 'import sys
sys.stdout.buffer.write(b"r14 long-window=21 payload row\n" * 80000)' >"$src"
src_sum=$(sha256sum "$src" | awk '{print $1}')

zstd -q --long=21 -o "$tmpdir/out.zst" "$src"
validator_require_file "$tmpdir/out.zst"

magic=$(od -An -N4 -tx1 "$tmpdir/out.zst" | tr -d ' \n')
test "$magic" = "28b52ffd"

zstd -tq "$tmpdir/out.zst"

# Decompression must mirror the same window log via --long.
zstd -dq --long=21 -c "$tmpdir/out.zst" >"$tmpdir/decoded.bin"
dst_sum=$(sha256sum "$tmpdir/decoded.bin" | awk '{print $1}')
[[ "$src_sum" == "$dst_sum" ]] || {
    printf 'sha256 mismatch after --long=21 roundtrip\n' >&2
    exit 1
}
