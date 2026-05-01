#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-bsdtar-options-level-22
# @title: bsdtar zstd:compression-level=22 max-tier round-trip
# @description: Creates a zstd-compressed tar with bsdtar --options 'zstd:compression-level=22' to drive the libarchive zstd encoder at the maximum ultra level, asserts the resulting archive carries the zstd frame magic, lists cleanly, extracts byte-for-byte, and is no larger than a default-level archive of the same payload.
# @timeout: 300
# @tags: usage, archive, zstd, bsdtar, level
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in" "$tmpdir/out"
python3 -c 'import sys
sys.stdout.buffer.write(b"level-22 ultra tier payload row\n" * 4096)' >"$tmpdir/in/payload.bin"
src_sum=$(sha256sum "$tmpdir/in/payload.bin" | awk '{print $1}')

bsdtar --zstd -cf "$tmpdir/default.tar.zst" -C "$tmpdir/in" payload.bin
bsdtar --zstd --options 'zstd:compression-level=22' \
  -cf "$tmpdir/u22.tar.zst" -C "$tmpdir/in" payload.bin
validator_require_file "$tmpdir/u22.tar.zst"

magic=$(od -An -N4 -tx1 "$tmpdir/u22.tar.zst" | tr -d ' \n')
test "$magic" = "28b52ffd"

size_default=$(stat -c %s "$tmpdir/default.tar.zst")
size_u22=$(stat -c %s "$tmpdir/u22.tar.zst")
# Ultra level must compress at least as well as the default level on this
# repetitive payload.
test "$size_u22" -le "$size_default"

bsdtar -tf "$tmpdir/u22.tar.zst" >"$tmpdir/list.txt"
grep -qx 'payload.bin' "$tmpdir/list.txt"

bsdtar -xf "$tmpdir/u22.tar.zst" -C "$tmpdir/out"
dst_sum=$(sha256sum "$tmpdir/out/payload.bin" | awk '{print $1}')
test "$src_sum" = "$dst_sum"
