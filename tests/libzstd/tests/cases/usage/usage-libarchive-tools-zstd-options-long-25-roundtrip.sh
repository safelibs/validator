#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-options-long-25-roundtrip
# @title: bsdtar zstd long-range mode 25 round-trip
# @description: Creates a zstd-compressed tar with --options 'zstd:long=25,zstd:compression-level=5' to combine long-range encoding with a non-default level and verifies the frame magic plus a sha256 round-trip.
# @timeout: 300
# @tags: usage, archive, zstd
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in" "$tmpdir/out"

# A repeating payload exercises the long-range matcher's window without
# blowing up the test runtime.
python3 -c '
import sys
chunk = b"long-range-25 segment payload\n"
sys.stdout.buffer.write(chunk * 4096)
' >"$tmpdir/in/payload.bin"

src_sum=$(sha256sum "$tmpdir/in/payload.bin" | awk '{print $1}')

bsdtar --zstd --options 'zstd:long=25,zstd:compression-level=5' \
  -cf "$tmpdir/a.tar.zst" -C "$tmpdir/in" payload.bin
validator_require_file "$tmpdir/a.tar.zst"

magic=$(od -An -N4 -tx1 "$tmpdir/a.tar.zst" | tr -d ' \n')
test "$magic" = "28b52ffd"

bsdtar -xf "$tmpdir/a.tar.zst" -C "$tmpdir/out"

dst_sum=$(sha256sum "$tmpdir/out/payload.bin" | awk '{print $1}')
test "$src_sum" = "$dst_sum"
