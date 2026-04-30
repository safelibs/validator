#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-cli-long-27-flag
# @title: zstd CLI --long=27 long-range mode round-trip
# @description: Compresses a payload via the standalone zstd CLI with --long=27 long-range mode, asserts the resulting frame carries the zstd magic and passes -t, and verifies it decompresses byte-for-byte back to the original input.
# @timeout: 240
# @tags: usage, archive, zstd, cli
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/payload.bin"
python3 -c 'import sys
sys.stdout.buffer.write(b"long-mode payload block\n" * 16384)' >"$src"
validator_require_file "$src"

zstd -q --long=27 -o "$tmpdir/long.zst" "$src"
validator_require_file "$tmpdir/long.zst"

magic=$(od -An -N4 -tx1 "$tmpdir/long.zst" | tr -d ' \n')
test "$magic" = "28b52ffd"

# Decoder must also be told to allow large windows.
zstd -tq --long=27 "$tmpdir/long.zst"
zstd -dq --long=27 -c "$tmpdir/long.zst" >"$tmpdir/decoded.bin"
cmp "$src" "$tmpdir/decoded.bin"

src_sum=$(sha256sum "$src" | awk '{print $1}')
dst_sum=$(sha256sum "$tmpdir/decoded.bin" | awk '{print $1}')
test "$src_sum" = "$dst_sum"
