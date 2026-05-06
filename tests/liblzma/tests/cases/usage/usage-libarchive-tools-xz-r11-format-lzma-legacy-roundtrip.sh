#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-r11-format-lzma-legacy-roundtrip
# @title: xz -F lzma legacy format encodes and decodes raw LZMA streams
# @description: Compresses a payload with -F lzma to produce a legacy LZMA stream (no .xz framing), confirms the file magic byte 0x5d, and round-trips back to byte-equal content via xz -F lzma -dc.
# @timeout: 60
# @tags: usage, xz, lzma-legacy
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 -c 'import sys
for i in range(128):
    sys.stdout.write("legacy lzma row %03d\n" % i)' >"$tmpdir/in.txt"
src_sha=$(sha256sum "$tmpdir/in.txt" | awk '{print $1}')

xz -F lzma -c "$tmpdir/in.txt" >"$tmpdir/out.lzma"

magic_byte=$(head -c 1 "$tmpdir/out.lzma" | od -An -tx1 | tr -d ' \n')
test "$magic_byte" = "5d"

xz -F lzma -dc "$tmpdir/out.lzma" >"$tmpdir/decoded.txt"
out_sha=$(sha256sum "$tmpdir/decoded.txt" | awk '{print $1}')
test "$src_sha" = "$out_sha"
