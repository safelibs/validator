#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-batch14-hardlink-count
# @title: bsdtar xz hardlink count after extract
# @description: Builds a tar.xz containing two hardlinked entries, extracts via liblzma, verifies file count is 2 and that both paths share the same inode.
# @timeout: 180
# @tags: usage, archive, xz
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in" "$tmpdir/out"
printf 'hardlink payload\n' >"$tmpdir/in/original.txt"
ln "$tmpdir/in/original.txt" "$tmpdir/in/linked.txt"

bsdtar -cJf "$tmpdir/a.tar.xz" -C "$tmpdir/in" original.txt linked.txt

magic_hex=$(head -c 6 "$tmpdir/a.tar.xz" | od -An -tx1 | tr -d ' \n')
test "$magic_hex" = "fd377a585a00"

bsdtar -xf "$tmpdir/a.tar.xz" -C "$tmpdir/out"

# Two regular files extracted
count=$(find "$tmpdir/out" -maxdepth 1 -type f | wc -l)
test "$count" = "2"

# Both paths must exist
test -f "$tmpdir/out/original.txt"
test -f "$tmpdir/out/linked.txt"

# They must share an inode (hardlink preserved)
ino_a=$(stat -c '%i' "$tmpdir/out/original.txt")
ino_b=$(stat -c '%i' "$tmpdir/out/linked.txt")
[[ "$ino_a" == "$ino_b" ]] || {
  printf 'expected hardlink: %s vs %s\n' "$ino_a" "$ino_b" >&2
  exit 1
}

cmp "$tmpdir/in/original.txt" "$tmpdir/out/original.txt"
cmp "$tmpdir/in/original.txt" "$tmpdir/out/linked.txt"
