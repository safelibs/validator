#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-binary-sha256-roundtrip
# @title: bsdtar zstd binary file sha256 round-trip
# @description: Round-trips a binary file with non-printable bytes through bsdtar --zstd and asserts the sha256 hash matches the original.
# @timeout: 180
# @tags: usage, archive, zstd
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in" "$tmpdir/out"

# Deterministic binary payload across the full byte range, repeated several times.
python3 -c '
import sys
buf = bytearray()
for _ in range(257):
    buf.extend(range(256))
sys.stdout.buffer.write(bytes(buf))
' >"$tmpdir/in/blob.bin"

src_sum=$(sha256sum "$tmpdir/in/blob.bin" | awk '{print $1}')

bsdtar --zstd -cf "$tmpdir/a.tar.zst" -C "$tmpdir/in" blob.bin
validator_require_file "$tmpdir/a.tar.zst"

magic=$(od -An -N4 -tx1 "$tmpdir/a.tar.zst" | tr -d ' \n')
test "$magic" = "28b52ffd"

bsdtar -xf "$tmpdir/a.tar.zst" -C "$tmpdir/out"

dst_sum=$(sha256sum "$tmpdir/out/blob.bin" | awk '{print $1}')
test "$src_sum" = "$dst_sum"
