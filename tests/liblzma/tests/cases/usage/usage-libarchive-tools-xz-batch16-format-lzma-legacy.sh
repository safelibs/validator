#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-batch16-format-lzma-legacy
# @title: xz -F lzma legacy then bsdtar reads
# @description: Creates a tar stream, compresses with xz -F lzma (legacy .lzma format), and confirms bsdtar can list and extract through liblzma.
# @timeout: 180
# @tags: usage, archive, xz, lzma
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/src" "$tmpdir/out"
printf 'legacy lzma payload\n' >"$tmpdir/src/alpha.txt"
printf 'second legacy entry\n' >"$tmpdir/src/beta.txt"

bsdtar -cf "$tmpdir/plain.tar" -C "$tmpdir/src" alpha.txt beta.txt
xz -F lzma -z -c "$tmpdir/plain.tar" >"$tmpdir/plain.tar.lzma"

# .lzma legacy magic begins with 5d 00 00
magic_hex=$(head -c 3 "$tmpdir/plain.tar.lzma" | od -An -tx1 | tr -d ' \n')
test "$magic_hex" = "5d0000"

bsdtar -tf "$tmpdir/plain.tar.lzma" >"$tmpdir/list"
validator_assert_contains "$tmpdir/list" 'alpha.txt'
validator_assert_contains "$tmpdir/list" 'beta.txt'

bsdtar -xf "$tmpdir/plain.tar.lzma" -C "$tmpdir/out"
cmp "$tmpdir/src/alpha.txt" "$tmpdir/out/alpha.txt"
cmp "$tmpdir/src/beta.txt" "$tmpdir/out/beta.txt"
