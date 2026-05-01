#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-batch18-hardlink-roundtrip
# @title: bsdtar xz roundtrip preserves hardlink pair
# @description: Stores a hardlinked file pair into a tar.xz, extracts elsewhere, and asserts the two extracted files share the same inode number so the hardlink relationship survives compression through liblzma.
# @timeout: 180
# @tags: usage, archive, xz, hardlink
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/src" "$tmpdir/out"
printf 'hardlink payload contents\n' >"$tmpdir/src/primary.txt"
ln "$tmpdir/src/primary.txt" "$tmpdir/src/twin.txt"

# Confirm the source pair is actually hardlinked.
src_inode=$(stat -c '%i' "$tmpdir/src/primary.txt")
src_twin_inode=$(stat -c '%i' "$tmpdir/src/twin.txt")
test "$src_inode" = "$src_twin_inode"

bsdtar -cJf "$tmpdir/a.tar.xz" -C "$tmpdir/src" primary.txt twin.txt

magic_hex=$(head -c 6 "$tmpdir/a.tar.xz" | od -An -tx1 | tr -d ' \n')
test "$magic_hex" = "fd377a585a00"

bsdtar -xf "$tmpdir/a.tar.xz" -C "$tmpdir/out"
test -f "$tmpdir/out/primary.txt"
test -f "$tmpdir/out/twin.txt"

out_a=$(stat -c '%i' "$tmpdir/out/primary.txt")
out_b=$(stat -c '%i' "$tmpdir/out/twin.txt")
[[ "$out_a" == "$out_b" ]] || {
  printf 'extracted hardlink pair has distinct inodes: %s vs %s\n' "$out_a" "$out_b" >&2
  exit 1
}
cmp "$tmpdir/src/primary.txt" "$tmpdir/out/primary.txt"
cmp "$tmpdir/src/primary.txt" "$tmpdir/out/twin.txt"
