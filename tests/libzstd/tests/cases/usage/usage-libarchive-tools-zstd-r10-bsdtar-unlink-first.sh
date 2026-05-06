#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r10-bsdtar-unlink-first
# @title: bsdtar zstd extract -U replaces existing entry
# @description: Pre-populates the destination file then extracts a zstd archive with -U (unlink-first), asserting bsdtar removes the old inode and writes the archive payload so the resulting sha256 matches the source.
# @timeout: 180
# @tags: usage, archive, zstd, extract
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in" "$tmpdir/out"
printf 'replacement payload\n' >"$tmpdir/in/note.txt"
src_sum=$(sha256sum "$tmpdir/in/note.txt" | awk '{print $1}')

bsdtar --zstd -cf "$tmpdir/a.tar.zst" -C "$tmpdir/in" note.txt

# Seed the destination with stale content so -U has something to unlink.
printf 'stale\n' >"$tmpdir/out/note.txt"
old_inode=$(stat -c %i "$tmpdir/out/note.txt")

bsdtar -xUf "$tmpdir/a.tar.zst" -C "$tmpdir/out"

dst_sum=$(sha256sum "$tmpdir/out/note.txt" | awk '{print $1}')
test "$src_sum" = "$dst_sum"

new_inode=$(stat -c %i "$tmpdir/out/note.txt")
test "$old_inode" != "$new_inode"
