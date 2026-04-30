#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-batch12-full-byte-range-roundtrip
# @title: bsdtar zstd full byte range round-trip
# @description: Round-trips a binary file containing every value 0x00 through 0xFF in a fixed permutation through bsdtar --zstd and asserts the sha256 hash matches after extraction, exercising raw byte preservation across the zstd filter.
# @timeout: 180
# @tags: usage, archive, zstd, binary
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in" "$tmpdir/out"

# A deterministic permutation of all 256 byte values, repeated to give the
# encoder enough material to exercise its tables. This also includes the NUL
# byte and 0xFF, which must round-trip verbatim.
python3 -c '
import sys
forward = bytes(range(256))
reverse = bytes(reversed(range(256)))
buf = bytearray()
for _ in range(64):
    buf.extend(forward)
    buf.extend(reverse)
sys.stdout.buffer.write(bytes(buf))
' >"$tmpdir/in/all-bytes.bin"

src_sum=$(sha256sum "$tmpdir/in/all-bytes.bin" | awk '{print $1}')

bsdtar --zstd -cf "$tmpdir/a.tar.zst" -C "$tmpdir/in" all-bytes.bin
validator_require_file "$tmpdir/a.tar.zst"

magic=$(od -An -N4 -tx1 "$tmpdir/a.tar.zst" | tr -d ' \n')
test "$magic" = "28b52ffd"

bsdtar -xf "$tmpdir/a.tar.zst" -C "$tmpdir/out"

dst_sum=$(sha256sum "$tmpdir/out/all-bytes.bin" | awk '{print $1}')
test "$src_sum" = "$dst_sum"

# Byte-for-byte parity is the strongest preservation guarantee.
cmp "$tmpdir/in/all-bytes.bin" "$tmpdir/out/all-bytes.bin"
