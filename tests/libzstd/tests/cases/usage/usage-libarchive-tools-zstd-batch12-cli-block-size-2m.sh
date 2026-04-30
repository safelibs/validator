#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-batch12-cli-block-size-2m
# @title: zstd CLI --long=20 round-trip
# @description: Compresses a payload with the standalone zstd CLI using --long=20 to enlarge the long-range matcher window to 1 MiB, verifies the .zst frame magic, and decompresses it back through bsdcat to confirm the bytes match.
# @timeout: 180
# @tags: usage, archive, zstd, cli
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in"

python3 -c '
import sys
chunk = b"block-size-2m payload segment\n"
sys.stdout.buffer.write(chunk * 8192)
' >"$tmpdir/in/payload.bin"

src_sum=$(sha256sum "$tmpdir/in/payload.bin" | awk '{print $1}')

zstd -q --long=20 -o "$tmpdir/payload.zst" "$tmpdir/in/payload.bin"
validator_require_file "$tmpdir/payload.zst"

magic=$(od -An -N4 -tx1 "$tmpdir/payload.zst" | tr -d ' \n')
test "$magic" = "28b52ffd"

# bsdcat understands raw zstd frames via libarchive's filter auto-detection.
bsdcat "$tmpdir/payload.zst" >"$tmpdir/out.bin"
dst_sum=$(sha256sum "$tmpdir/out.bin" | awk '{print $1}')
test "$src_sum" = "$dst_sum"
