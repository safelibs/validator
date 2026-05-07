#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r14-bsdtar-use-compress-program
# @title: bsdtar --use-compress-program=zstd pipes the archive through the external zstd CLI
# @description: Builds a tar with bsdtar --use-compress-program=zstd, asserts the resulting payload begins with the standard zstd frame magic, lists cleanly via bsdtar -tf, and extracts to a tree whose contents match the source SHA-256 byte-for-byte.
# @timeout: 120
# @tags: usage, archive, bsdtar, compress-program
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/src"
mkdir -p "$src"
printf 'r14 use-compress-program file a\n' >"$src/a.txt"
printf 'r14 use-compress-program file b\n' >"$src/b.txt"
a_sum=$(sha256sum "$src/a.txt" | awk '{print $1}')
b_sum=$(sha256sum "$src/b.txt" | awk '{print $1}')

archive="$tmpdir/out.tar.zst"
bsdtar --use-compress-program=zstd -cf "$archive" -C "$src" a.txt b.txt
validator_require_file "$archive"

magic=$(od -An -N4 -tx1 "$archive" | tr -d ' \n')
test "$magic" = "28b52ffd"

bsdtar -tf "$archive" >"$tmpdir/listing"
grep -q '^a.txt$' "$tmpdir/listing"
grep -q '^b.txt$' "$tmpdir/listing"

dest="$tmpdir/dest"
mkdir -p "$dest"
bsdtar -xf "$archive" -C "$dest"
[[ "$a_sum" == "$(sha256sum "$dest/a.txt" | awk '{print $1}')" ]]
[[ "$b_sum" == "$(sha256sum "$dest/b.txt" | awk '{print $1}')" ]]
