#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-options-level-19
# @title: bsdtar zstd compression-level 19
# @description: Creates a zstd-compressed tar at --options zstd:compression-level=19 and verifies sha256 round-trip equality.
# @timeout: 300
# @tags: usage, archive, zstd
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in" "$tmpdir/out"
# Generate a 64 KiB deterministic payload that benefits from higher levels.
python3 -c '
import os, sys
data = bytearray()
for i in range(64 * 1024):
    data.append((i * 1103515245 + 12345) & 0xff)
sys.stdout.buffer.write(bytes(data))
' >"$tmpdir/in/payload.bin"

bsdtar --zstd --options 'zstd:compression-level=19' \
  -cf "$tmpdir/a.tar.zst" -C "$tmpdir/in" payload.bin
validator_require_file "$tmpdir/a.tar.zst"

magic=$(od -An -N4 -tx1 "$tmpdir/a.tar.zst" | tr -d ' \n')
test "$magic" = "28b52ffd"

bsdtar -xf "$tmpdir/a.tar.zst" -C "$tmpdir/out"

src_sum=$(sha256sum "$tmpdir/in/payload.bin" | awk '{print $1}')
dst_sum=$(sha256sum "$tmpdir/out/payload.bin" | awk '{print $1}')
test "$src_sum" = "$dst_sum"
