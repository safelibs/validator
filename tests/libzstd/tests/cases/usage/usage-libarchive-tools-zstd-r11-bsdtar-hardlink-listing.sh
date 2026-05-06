#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r11-bsdtar-hardlink-listing
# @title: bsdtar --zstd verbose listing reports hardlink relationship
# @description: Builds a zstd tar containing two hardlinked entries to the same inode and verifies bsdtar -tvf annotates the second entry with a "link to" reference back to the first.
# @timeout: 120
# @tags: usage, archive, zstd, hardlink
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in"
printf 'shared\n' >"$tmpdir/in/orig.txt"
ln "$tmpdir/in/orig.txt" "$tmpdir/in/dup.txt"

bsdtar --zstd -cf "$tmpdir/hl.tar.zst" -C "$tmpdir/in" orig.txt dup.txt
bsdtar -tvf "$tmpdir/hl.tar.zst" >"$tmpdir/list"

grep -E 'orig\.txt|dup\.txt' "$tmpdir/list" >/dev/null
grep -F 'link to' "$tmpdir/list" >/dev/null
