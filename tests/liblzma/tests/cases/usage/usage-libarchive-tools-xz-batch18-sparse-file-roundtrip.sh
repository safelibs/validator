#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-batch18-sparse-file-roundtrip
# @title: bsdtar xz roundtrip on a sparse file
# @description: Creates a sparse file with a hole between two byte regions, stores it in a tar.xz, extracts elsewhere, and confirms the apparent size and SHA-256 match while the file body is preserved through liblzma.
# @timeout: 180
# @tags: usage, archive, xz, sparse
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/src" "$tmpdir/out"

# Build a sparse file: 1 MiB apparent size with a small head and tail, hole in the middle.
truncate -s 1M "$tmpdir/src/sparse.bin"
printf 'HEAD' | dd of="$tmpdir/src/sparse.bin" bs=1 count=4 conv=notrunc status=none
printf 'TAIL' | dd of="$tmpdir/src/sparse.bin" bs=1 count=4 seek=$((1024*1024 - 4)) conv=notrunc status=none

src_size=$(stat -c '%s' "$tmpdir/src/sparse.bin")
test "$src_size" -eq 1048576
src_sha=$(sha256sum "$tmpdir/src/sparse.bin" | awk '{print $1}')

bsdtar -cJf "$tmpdir/a.tar.xz" -C "$tmpdir/src" sparse.bin

magic_hex=$(head -c 6 "$tmpdir/a.tar.xz" | od -An -tx1 | tr -d ' \n')
test "$magic_hex" = "fd377a585a00"

bsdtar -xf "$tmpdir/a.tar.xz" -C "$tmpdir/out"
out_size=$(stat -c '%s' "$tmpdir/out/sparse.bin")
test "$out_size" -eq 1048576
out_sha=$(sha256sum "$tmpdir/out/sparse.bin" | awk '{print $1}')
[[ "$src_sha" == "$out_sha" ]] || {
  printf 'sparse roundtrip sha mismatch: %s vs %s\n' "$src_sha" "$out_sha" >&2
  exit 1
}
