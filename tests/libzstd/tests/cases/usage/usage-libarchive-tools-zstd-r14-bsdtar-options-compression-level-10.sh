#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r14-bsdtar-options-compression-level-10
# @title: bsdtar --options zstd:compression-level=10 selects an explicit zstd level
# @description: Builds a zstd-compressed tar with bsdtar --zstd and --options zstd:compression-level=10 to set an explicit compression level, asserts the resulting archive starts with the zstd frame magic, lists the expected entries through bsdtar -tf, and extracts to a tree whose contents round-trip byte-for-byte.
# @timeout: 120
# @tags: usage, archive, bsdtar, options
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/src"
mkdir -p "$src"
python3 -c 'import sys
sys.stdout.buffer.write(b"r14 options zstd compression-level=10 row\n" * 200)' >"$src/data.bin"
data_sum=$(sha256sum "$src/data.bin" | awk '{print $1}')

archive="$tmpdir/out.tar.zst"
bsdtar --zstd --options 'zstd:compression-level=10' -cf "$archive" -C "$src" data.bin
validator_require_file "$archive"

magic=$(od -An -N4 -tx1 "$archive" | tr -d ' \n')
test "$magic" = "28b52ffd"

bsdtar -tf "$archive" >"$tmpdir/listing"
grep -q '^data.bin$' "$tmpdir/listing"

dest="$tmpdir/dest"
mkdir -p "$dest"
bsdtar -xf "$archive" -C "$dest"
[[ "$data_sum" == "$(sha256sum "$dest/data.bin" | awk '{print $1}')" ]]
