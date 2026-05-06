#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r10-zstd-cli-fast-mode-1
# @title: zstd CLI --fast=1 negative-level encode
# @description: Compresses a repeating payload with zstd --fast=1 to drive the negative-level fast encoder, verifies the .zst frame magic, and confirms the payload sha256 round-trips through decompression.
# @timeout: 180
# @tags: usage, archive, zstd, cli, fast
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# A repeating payload large enough to exercise the fast-mode encoder.
python3 -c '
import sys
chunk = b"fast-mode payload segment\n"
sys.stdout.buffer.write(chunk * 4096)
' >"$tmpdir/payload.bin"

src_sum=$(sha256sum "$tmpdir/payload.bin" | awk '{print $1}')

zstd -q --fast=1 -o "$tmpdir/payload.zst" "$tmpdir/payload.bin"
validator_require_file "$tmpdir/payload.zst"

magic=$(od -An -N4 -tx1 "$tmpdir/payload.zst" | tr -d ' \n')
test "$magic" = "28b52ffd"

zstd -dq -o "$tmpdir/payload.out" "$tmpdir/payload.zst"
dst_sum=$(sha256sum "$tmpdir/payload.out" | awk '{print $1}')
test "$src_sum" = "$dst_sum"
