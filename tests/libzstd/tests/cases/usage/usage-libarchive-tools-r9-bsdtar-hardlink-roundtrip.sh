#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-r9-bsdtar-hardlink-roundtrip
# @title: bsdtar zstd preserves hardlink relationship
# @description: Creates a file and a hardlink, archives both into a zstd tar, extracts and asserts the extracted pair shares the same inode (or content) and links count is at least two.
# @timeout: 180
# @tags: usage, archive, zstd
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in" "$tmpdir/out"
printf 'shared inode payload\n' >"$tmpdir/in/a.txt"
ln "$tmpdir/in/a.txt" "$tmpdir/in/b.txt"

bsdtar --zstd -cf "$tmpdir/a.tar.zst" -C "$tmpdir/in" .
bsdtar -xf "$tmpdir/a.tar.zst" -C "$tmpdir/out"

ino_a=$(stat -c '%i' "$tmpdir/out/a.txt")
ino_b=$(stat -c '%i' "$tmpdir/out/b.txt")
[[ "$ino_a" == "$ino_b" ]] || { echo "inodes differ a=$ino_a b=$ino_b" >&2; exit 1; }

links=$(stat -c '%h' "$tmpdir/out/a.txt")
[[ "$links" -ge 2 ]] || { echo "expected nlink>=2 got $links" >&2; exit 1; }
