#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-r14-lzma-keep-then-decompress
# @title: lzma --keep then --decompress sequence preserves source and recovers payload
# @description: Compresses a payload via "lzma --keep" (legacy lzma format), asserts the .lzma file appears alongside an untouched source, then decompresses with "lzma --decompress -c" and verifies the recovered bytes match the source sha256.
# @timeout: 60
# @tags: usage, lzma, keep
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'lzma keep then decompress payload\n' >"$tmpdir/in.txt"
src_sha=$(sha256sum "$tmpdir/in.txt" | awk '{print $1}')

lzma --keep "$tmpdir/in.txt"
[[ -f "$tmpdir/in.txt.lzma" ]]
[[ -f "$tmpdir/in.txt" ]]
post_sha=$(sha256sum "$tmpdir/in.txt" | awk '{print $1}')
test "$src_sha" = "$post_sha"

# Legacy .lzma starts with 0x5d.
magic_byte=$(head -c 1 "$tmpdir/in.txt.lzma" | od -An -tx1 | tr -d ' \n')
test "$magic_byte" = "5d"

lzma --decompress -c "$tmpdir/in.txt.lzma" >"$tmpdir/decoded.txt"
test "$src_sha" = "$(sha256sum "$tmpdir/decoded.txt" | awk '{print $1}')"
