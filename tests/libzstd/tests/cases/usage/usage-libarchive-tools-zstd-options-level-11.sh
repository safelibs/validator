#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-options-level-11
# @title: bsdtar zstd compression-level 11
# @description: Creates a zstd-compressed tar with bsdtar using --options 'zstd:compression-level=11' (a mid-range level), verifies the archive magic, then extracts and asserts the payload round-trips by sha256.
# @timeout: 240
# @tags: usage, archive, zstd
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in" "$tmpdir/out"
python3 -c 'import sys
sys.stdout.buffer.write(b"level-11 mid payload row\n" * 1024)' >"$tmpdir/in/payload.bin"
src_sum=$(sha256sum "$tmpdir/in/payload.bin" | awk '{print $1}')

bsdtar --zstd --options 'zstd:compression-level=11' \
  -cf "$tmpdir/a.tar.zst" -C "$tmpdir/in" payload.bin
validator_require_file "$tmpdir/a.tar.zst"

magic=$(od -An -N4 -tx1 "$tmpdir/a.tar.zst" | tr -d ' \n')
test "$magic" = "28b52ffd"

bsdtar -xf "$tmpdir/a.tar.zst" -C "$tmpdir/out"
validator_require_file "$tmpdir/out/payload.bin"
dst_sum=$(sha256sum "$tmpdir/out/payload.bin" | awk '{print $1}')
test "$src_sum" = "$dst_sum"
