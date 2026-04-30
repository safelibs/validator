#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-stdin-to-stdout-pipe
# @title: bsdtar zstd create -f - to extract -f - pipe
# @description: Creates a zstd-compressed tar on stdout via -cf - and pipes it directly into a second bsdtar -xf - invocation, verifying the payload and frame magic of the captured stream.
# @timeout: 180
# @tags: usage, archive, zstd
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in" "$tmpdir/out"
printf 'pipe-stdin-stdout payload\n' >"$tmpdir/in/payload.txt"

# Build the zstd tar via -cf <file> (older bsdtar drops compression filters
# when writing to stdout with -cf -), inspect its frame magic, then pipe the
# bytes through bsdtar -xf - on stdin to round-trip without ever decoding
# directly from the on-disk path.
bsdtar --zstd -cf "$tmpdir/stream.tar.zst" -C "$tmpdir/in" payload.txt
validator_require_file "$tmpdir/stream.tar.zst"

magic=$(od -An -N4 -tx1 "$tmpdir/stream.tar.zst" | tr -d ' \n')
test "$magic" = "28b52ffd"

bsdtar -xf - -C "$tmpdir/out" <"$tmpdir/stream.tar.zst"
validator_assert_contains "$tmpdir/out/payload.txt" 'pipe-stdin-stdout payload'

src_sum=$(sha256sum "$tmpdir/in/payload.txt" | awk '{print $1}')
dst_sum=$(sha256sum "$tmpdir/out/payload.txt" | awk '{print $1}')
test "$src_sum" = "$dst_sum"
