#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-bsdtar-options-threads-2
# @title: bsdtar zstd:threads=2 multi-worker create
# @description: Creates a zstd-compressed tar with bsdtar --options 'zstd:threads=2' to drive the libarchive zstd writer with two worker threads, asserts the output carries the zstd magic, lists cleanly, and extracts to a sha256-identical copy of the source tree.
# @timeout: 180
# @tags: usage, archive, zstd, bsdtar, threads
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in" "$tmpdir/out"
python3 -c 'import sys
sys.stdout.buffer.write(b"two-thread bsdtar payload row\n" * 4096)' >"$tmpdir/in/big.bin"
printf 'aux\n' >"$tmpdir/in/aux.txt"

bsdtar --zstd --options 'zstd:threads=2' \
  -cf "$tmpdir/a.tar.zst" -C "$tmpdir/in" big.bin aux.txt
validator_require_file "$tmpdir/a.tar.zst"

magic=$(od -An -N4 -tx1 "$tmpdir/a.tar.zst" | tr -d ' \n')
test "$magic" = "28b52ffd"

bsdtar -tf "$tmpdir/a.tar.zst" >"$tmpdir/list.txt"
grep -qx 'big.bin' "$tmpdir/list.txt"
grep -qx 'aux.txt' "$tmpdir/list.txt"

bsdtar -xf "$tmpdir/a.tar.zst" -C "$tmpdir/out"
src_sum=$(sha256sum "$tmpdir/in/big.bin" | awk '{print $1}')
dst_sum=$(sha256sum "$tmpdir/out/big.bin" | awk '{print $1}')
test "$src_sum" = "$dst_sum"
