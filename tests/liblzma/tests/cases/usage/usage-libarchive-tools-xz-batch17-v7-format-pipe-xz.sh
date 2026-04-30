#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-batch17-v7-format-pipe-xz
# @title: bsdtar --format=v7 piped through xz
# @description: Creates a v7 (legacy pre-POSIX) tar with bsdtar --format=v7, pipes through xz, and confirms bsdtar reads it back through liblzma with byte-identical contents.
# @timeout: 180
# @tags: usage, archive, xz, v7, format
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in" "$tmpdir/out"
# v7 tar restricts filenames to <=99 bytes and has no extended attributes;
# stick to short ASCII names to stay within the format.
printf 'v7 alpha\n' >"$tmpdir/in/alpha.txt"
printf 'v7 beta payload\n' >"$tmpdir/in/beta.txt"
src_sha_alpha=$(sha256sum "$tmpdir/in/alpha.txt" | awk '{print $1}')
src_sha_beta=$(sha256sum "$tmpdir/in/beta.txt" | awk '{print $1}')

# Create a v7 tar on stdout, compress with xz, capture to disk.
bsdtar -c --format=v7 -C "$tmpdir/in" alpha.txt beta.txt | xz -z -c >"$tmpdir/a.tar.xz"

# .xz magic
magic_hex=$(head -c 6 "$tmpdir/a.tar.xz" | od -An -tx1 | tr -d ' \n')
test "$magic_hex" = "fd377a585a00"

# bsdtar reads the resulting xz-compressed v7 tar.
bsdtar -tf "$tmpdir/a.tar.xz" >"$tmpdir/list.txt"
validator_assert_contains "$tmpdir/list.txt" 'alpha.txt'
validator_assert_contains "$tmpdir/list.txt" 'beta.txt'

bsdtar -xf "$tmpdir/a.tar.xz" -C "$tmpdir/out"
out_sha_alpha=$(sha256sum "$tmpdir/out/alpha.txt" | awk '{print $1}')
out_sha_beta=$(sha256sum "$tmpdir/out/beta.txt" | awk '{print $1}')
test "$src_sha_alpha" = "$out_sha_alpha"
test "$src_sha_beta" = "$out_sha_beta"
