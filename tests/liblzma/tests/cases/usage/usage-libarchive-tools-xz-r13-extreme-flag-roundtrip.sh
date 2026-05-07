#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-r13-extreme-flag-roundtrip
# @title: xz -e extreme flag roundtrips a compressible payload
# @description: Compresses a 64KB highly repetitive payload with "xz -e -c" (extreme flag), verifies the .xz magic, and decompresses back via "xz -d -c" asserting source sha256 matches the recovered output.
# @timeout: 90
# @tags: usage, xz, extreme
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# 64 KiB of compressible content.
python3 -c '
import sys
sys.stdout.buffer.write((b"abcdefghijklmnop" * (64 * 1024 // 16)))
' >"$tmpdir/in.bin"

src_sha=$(sha256sum "$tmpdir/in.bin" | awk '{print $1}')

xz -e -c "$tmpdir/in.bin" >"$tmpdir/out.xz"

magic_hex=$(head -c 6 "$tmpdir/out.xz" | od -An -tx1 | tr -d ' \n')
test "$magic_hex" = "fd377a585a00"

xz -d -c "$tmpdir/out.xz" >"$tmpdir/decoded.bin"
test "$src_sha" = "$(sha256sum "$tmpdir/decoded.bin" | awk '{print $1}')"
