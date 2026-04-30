#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-bsdtar-hardlink-preservation
# @title: bsdtar --zstd preserves hardlink linkage
# @description: Builds a tree with a hardlinked file pair, archives it with bsdtar --zstd, extracts to a fresh directory, and asserts the extracted pair shares an inode (libarchive recreated the hardlink) and both files contain the original payload.
# @timeout: 180
# @tags: usage, archive, zstd
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in" "$tmpdir/out"
printf 'hardlink preservation payload\n' >"$tmpdir/in/original.txt"
ln "$tmpdir/in/original.txt" "$tmpdir/in/alias.txt"
src_sum=$(sha256sum "$tmpdir/in/original.txt" | awk '{print $1}')

bsdtar --zstd -cf "$tmpdir/a.tar.zst" -C "$tmpdir/in" original.txt alias.txt
validator_require_file "$tmpdir/a.tar.zst"

magic=$(od -An -N4 -tx1 "$tmpdir/a.tar.zst" | tr -d ' \n')
test "$magic" = "28b52ffd"

bsdtar -xf "$tmpdir/a.tar.zst" -C "$tmpdir/out"
validator_require_file "$tmpdir/out/original.txt"
validator_require_file "$tmpdir/out/alias.txt"

inode_a=$(stat -c %i "$tmpdir/out/original.txt")
inode_b=$(stat -c %i "$tmpdir/out/alias.txt")
test "$inode_a" = "$inode_b" || {
  printf 'expected hardlink to be preserved on extraction (inodes %s vs %s)\n' "$inode_a" "$inode_b" >&2
  exit 1
}

dst_sum=$(sha256sum "$tmpdir/out/original.txt" | awk '{print $1}')
test "$src_sum" = "$dst_sum"
cmp "$tmpdir/out/original.txt" "$tmpdir/out/alias.txt"
