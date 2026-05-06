#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-r11-lzma2-preset-modifier
# @title: xz --lzma2=preset=3 explicit filter syntax round-trips payload
# @description: Builds a stream using the explicit "--lzma2=preset=3" filter modifier and verifies xz -dc decodes it back to byte-equal content while xz --robot --list reports a single stream with one block.
# @timeout: 60
# @tags: usage, xz, filter
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 -c 'import sys
for i in range(64):
    sys.stdout.write("preset3 row %03d alpha beta gamma\n" % i)' >"$tmpdir/in.txt"
src_sha=$(sha256sum "$tmpdir/in.txt" | awk '{print $1}')

xz --lzma2=preset=3 -c "$tmpdir/in.txt" >"$tmpdir/out.xz"

magic_hex=$(head -c 6 "$tmpdir/out.xz" | od -An -tx1 | tr -d ' \n')
test "$magic_hex" = "fd377a585a00"

xz --robot --list "$tmpdir/out.xz" >"$tmpdir/list.txt"
totals_streams=$(awk '$1=="totals"{print $2}' "$tmpdir/list.txt")
totals_blocks=$(awk '$1=="totals"{print $3}' "$tmpdir/list.txt")
test "$totals_streams" = "1"
test "$totals_blocks" = "1"

xz -dc "$tmpdir/out.xz" >"$tmpdir/decoded.txt"
out_sha=$(sha256sum "$tmpdir/decoded.txt" | awk '{print $1}')
test "$src_sha" = "$out_sha"
