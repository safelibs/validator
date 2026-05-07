#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r15-bsdtar-options-compression-level-5
# @title: bsdtar --options=zstd:compression-level=5 produces a valid zstd-wrapped tar that round-trips
# @description: Creates a zstd-compressed tar with bsdtar --options 'zstd:compression-level=5', asserts the resulting archive starts with the zstd frame magic, lists cleanly, and extracts back to a byte-identical SHA-256 of every source member.
# @timeout: 60
# @tags: usage, archive, bsdtar, options, compression-level
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/src"
mkdir -p "$src"
printf 'r15 level=5 file alpha\n' >"$src/a.txt"
printf 'r15 level=5 file bravo\n' >"$src/b.txt"
a_sum=$(sha256sum "$src/a.txt" | awk '{print $1}')
b_sum=$(sha256sum "$src/b.txt" | awk '{print $1}')

archive="$tmpdir/out.tar.zst"
bsdtar --options 'zstd:compression-level=5' --zstd -cf "$archive" -C "$src" a.txt b.txt
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
