#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-bsdtar-pipe-zstd-cli
# @title: bsdtar plain tar piped through zstd CLI then back
# @description: Exercises the cross-tool pipeline that uses bsdtar to write a plain tar to stdout, the zstd CLI to compress that stream into a .tar.zst, and bsdtar again to list and extract the result so the libarchive reader and the zstd CLI compressor are validated together with a sha256 round-trip.
# @timeout: 180
# @tags: usage, archive, zstd, bsdtar, pipe
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in" "$tmpdir/out"
python3 -c 'import sys
sys.stdout.buffer.write(b"bsdtar zstd pipe payload\n" * 1024)' >"$tmpdir/in/data.bin"
src_sum=$(sha256sum "$tmpdir/in/data.bin" | awk '{print $1}')

bsdtar -cf - -C "$tmpdir/in" data.bin | zstd -q -o "$tmpdir/piped.tar.zst"
validator_require_file "$tmpdir/piped.tar.zst"

magic=$(od -An -N4 -tx1 "$tmpdir/piped.tar.zst" | tr -d ' \n')
test "$magic" = "28b52ffd"

zstd -tq "$tmpdir/piped.tar.zst"

bsdtar -tf "$tmpdir/piped.tar.zst" >"$tmpdir/list.txt"
grep -qx 'data.bin' "$tmpdir/list.txt"

bsdtar -xf "$tmpdir/piped.tar.zst" -C "$tmpdir/out"
dst_sum=$(sha256sum "$tmpdir/out/data.bin" | awk '{print $1}')
test "$src_sum" = "$dst_sum"
