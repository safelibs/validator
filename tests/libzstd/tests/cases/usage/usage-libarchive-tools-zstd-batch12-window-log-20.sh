#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-batch12-window-log-20
# @title: bsdtar zstd compression-level round-trip
# @description: Creates a zstd-compressed tar with --options 'zstd:compression-level=20' to drive the encoder at a high level, verifies the frame magic, and confirms a sha256 round-trip through extraction.
# @timeout: 180
# @tags: usage, archive, zstd, options
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in" "$tmpdir/out"

# A repeating payload that comfortably fits within a 1 MiB window (2^20).
python3 -c '
import sys
chunk = b"window-log-20 segment payload\n"
sys.stdout.buffer.write(chunk * 2048)
' >"$tmpdir/in/payload.bin"

src_sum=$(sha256sum "$tmpdir/in/payload.bin" | awk '{print $1}')

bsdtar --zstd --options 'zstd:compression-level=20' \
  -cf "$tmpdir/a.tar.zst" -C "$tmpdir/in" payload.bin
validator_require_file "$tmpdir/a.tar.zst"

magic=$(od -An -N4 -tx1 "$tmpdir/a.tar.zst" | tr -d ' \n')
test "$magic" = "28b52ffd"

bsdtar -xf "$tmpdir/a.tar.zst" -C "$tmpdir/out"

dst_sum=$(sha256sum "$tmpdir/out/payload.bin" | awk '{print $1}')
test "$src_sum" = "$dst_sum"
