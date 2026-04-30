#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-bsdtar-compression-level-15
# @title: bsdtar zstd compression-level=15 round-trip
# @description: Creates a zstd-compressed tar via bsdtar with --options 'zstd:compression-level=15' to drive the encoder at a high mid-tier level, verifies the archive's zstd frame magic, and confirms a sha256 round-trip after extraction.
# @timeout: 180
# @tags: usage, archive, zstd, options
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in" "$tmpdir/out"

python3 -c '
import sys
chunk = b"compression-level-15 segment payload\n"
sys.stdout.buffer.write(chunk * 4096)
' >"$tmpdir/in/payload.bin"

src_sum=$(sha256sum "$tmpdir/in/payload.bin" | awk '{print $1}')

bsdtar --zstd --options 'zstd:compression-level=15' \
  -cf "$tmpdir/a.tar.zst" -C "$tmpdir/in" payload.bin
validator_require_file "$tmpdir/a.tar.zst"

magic=$(od -An -N4 -tx1 "$tmpdir/a.tar.zst" | tr -d ' \n')
test "$magic" = "28b52ffd"

bsdtar -xf "$tmpdir/a.tar.zst" -C "$tmpdir/out"

dst_sum=$(sha256sum "$tmpdir/out/payload.bin" | awk '{print $1}')
test "$src_sum" = "$dst_sum"
