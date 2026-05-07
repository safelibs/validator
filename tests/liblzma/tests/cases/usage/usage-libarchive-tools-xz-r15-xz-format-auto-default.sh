#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-r15-xz-format-auto-default
# @title: xz -F auto on decompress accepts both .xz and legacy .lzma inputs
# @description: Builds two compressed payloads from the same source — one with "xz -c" producing a .xz (fd 37 7a 58 5a 00) and one with "lzma -c" producing a legacy .lzma (5d ...) — then decompresses both via "xz -F auto -dc" (the format-detection mode) and asserts the recovered bytes match the source sha256 in both directions, exercising the auto-format detection path explicitly.
# @timeout: 60
# @tags: usage, xz, format, auto
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'r15 xz format-auto payload alpha beta\n' >"$tmpdir/in.txt"
src_sha=$(sha256sum "$tmpdir/in.txt" | awk '{print $1}')

xz   -c "$tmpdir/in.txt" >"$tmpdir/out.xz"
lzma -c "$tmpdir/in.txt" >"$tmpdir/out.lzma"

# Sanity-check the two distinct magics.
xz_magic=$(head -c 6 "$tmpdir/out.xz" | od -An -tx1 | tr -d ' \n')
test "$xz_magic" = "fd377a585a00"
lzma_byte=$(head -c 1 "$tmpdir/out.lzma" | od -An -tx1 | tr -d ' \n')
test "$lzma_byte" = "5d"

# xz -F auto -dc accepts both formats.
xz -F auto -dc "$tmpdir/out.xz"   >"$tmpdir/d_xz.txt"
xz -F auto -dc "$tmpdir/out.lzma" >"$tmpdir/d_lzma.txt"

test "$src_sha" = "$(sha256sum "$tmpdir/d_xz.txt"   | awk '{print $1}')"
test "$src_sha" = "$(sha256sum "$tmpdir/d_lzma.txt" | awk '{print $1}')"
