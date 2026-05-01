#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-bsdtar-compression-level-7
# @title: bsdtar zstd compression-level=7 mid-tier
# @description: Creates a zstd-compressed tar with bsdtar --options 'zstd:compression-level=7' to exercise the mid-tier libarchive level wiring, asserts the output carries the zstd magic, lists cleanly, and extracts to a sha256-identical copy of the source payload.
# @timeout: 180
# @tags: usage, archive, zstd, bsdtar, level
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in" "$tmpdir/out"
python3 -c 'import sys
sys.stdout.buffer.write(b"level-7 bsdtar payload chunk\n" * 4096)' >"$tmpdir/in/payload.bin"

bsdtar --zstd --options 'zstd:compression-level=7' \
  -cf "$tmpdir/a.tar.zst" -C "$tmpdir/in" payload.bin
validator_require_file "$tmpdir/a.tar.zst"

magic=$(od -An -N4 -tx1 "$tmpdir/a.tar.zst" | tr -d ' \n')
test "$magic" = "28b52ffd"

bsdtar -tf "$tmpdir/a.tar.zst" >"$tmpdir/list.txt"
grep -qx 'payload.bin' "$tmpdir/list.txt"

bsdtar -xf "$tmpdir/a.tar.zst" -C "$tmpdir/out"
src_sum=$(sha256sum "$tmpdir/in/payload.bin" | awk '{print $1}')
dst_sum=$(sha256sum "$tmpdir/out/payload.bin" | awk '{print $1}')
test "$src_sum" = "$dst_sum"

src_size=$(stat -c %s "$tmpdir/in/payload.bin")
zst_size=$(stat -c %s "$tmpdir/a.tar.zst")
test "$zst_size" -lt "$src_size"
