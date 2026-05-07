#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-r12-bsdtar-lzma-format-roundtrip
# @title: bsdtar --lzma create and extract roundtrips a tarball
# @description: Builds a tar.lzma archive with "bsdtar --lzma -cf" against a directory of two files, verifies the on-disk magic byte 0x5d, and round-trips through "bsdtar -xf" auto-detection to recover both source files byte-for-byte.
# @timeout: 60
# @tags: usage, bsdtar, lzma
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in" "$tmpdir/out"
printf 'bsdtar lzma alpha\n' >"$tmpdir/in/a.txt"
printf 'bsdtar lzma beta\n' >"$tmpdir/in/b.txt"

a_sha=$(sha256sum "$tmpdir/in/a.txt" | awk '{print $1}')
b_sha=$(sha256sum "$tmpdir/in/b.txt" | awk '{print $1}')

bsdtar --lzma -cf "$tmpdir/out.tar.lzma" -C "$tmpdir/in" a.txt b.txt

magic_byte=$(head -c 1 "$tmpdir/out.tar.lzma" | od -An -tx1 | tr -d ' \n')
test "$magic_byte" = "5d"

bsdtar -xf "$tmpdir/out.tar.lzma" -C "$tmpdir/out"
out_a_sha=$(sha256sum "$tmpdir/out/a.txt" | awk '{print $1}')
out_b_sha=$(sha256sum "$tmpdir/out/b.txt" | awk '{print $1}')
test "$a_sha" = "$out_a_sha"
test "$b_sha" = "$out_b_sha"
