#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-batch17-tf-creation-order
# @title: bsdtar -tf preserves creation order
# @description: Adds files to a tar.xz archive in a specific argv order and asserts bsdtar -tf lists them in that exact order, confirming liblzma decoding does not reorder entries.
# @timeout: 180
# @tags: usage, archive, xz, ordering
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in" "$tmpdir/out"
# Create a deliberately non-alphabetical input order so we can detect reordering.
for n in zeta alpha middle beta yankee; do
  printf 'payload %s\n' "$n" >"$tmpdir/in/$n.txt"
done

# Pass argv in this exact non-sorted order. bsdtar must store them in argv order.
bsdtar -cJf "$tmpdir/a.tar.xz" -C "$tmpdir/in" \
  zeta.txt alpha.txt middle.txt beta.txt yankee.txt

# .xz magic
magic_hex=$(head -c 6 "$tmpdir/a.tar.xz" | od -An -tx1 | tr -d ' \n')
test "$magic_hex" = "fd377a585a00"

bsdtar -tf "$tmpdir/a.tar.xz" >"$tmpdir/list.txt"

expected=$(printf 'zeta.txt\nalpha.txt\nmiddle.txt\nbeta.txt\nyankee.txt\n')
actual=$(cat "$tmpdir/list.txt")
[[ "$expected" == "$actual" ]] || {
  printf 'order mismatch:\nexpected:\n%s\nactual:\n%s\n' "$expected" "$actual" >&2
  exit 1
}
