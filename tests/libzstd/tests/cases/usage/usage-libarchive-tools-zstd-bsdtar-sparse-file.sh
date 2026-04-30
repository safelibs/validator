#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-bsdtar-sparse-file
# @title: bsdtar zstd round-trip with a sparse file
# @description: Builds a sparse file (1 MiB logical size with a small data segment near the end and an explicit hole at the front), archives it through bsdtar --zstd, extracts to a fresh directory, and verifies that the extracted file has the same logical size, the same sha256 byte content (holes read as zeros) and that the data segment near the end is preserved verbatim.
# @timeout: 180
# @tags: usage, archive, zstd, bsdtar, sparse
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in" "$tmpdir/out"
src="$tmpdir/in/sparse.bin"

# Build a 1 MiB sparse file: hole from offset 0 to 1MiB-32, then 32 bytes of data.
python3 -c '
import os, sys
path = sys.argv[1]
size = 1 << 20
tail = b"sparse-tail-marker-payload-32by"  # 31 bytes
tail += b"\n"                               # 32 bytes total
with open(path, "wb") as fh:
    fh.truncate(size)
    fh.seek(size - len(tail))
    fh.write(tail)
assert os.path.getsize(path) == size
' "$src"
validator_require_file "$src"

src_size=$(stat -c %s "$src")
test "$src_size" = "1048576"
src_sum=$(sha256sum "$src" | awk '{print $1}')

bsdtar --zstd -cf "$tmpdir/a.tar.zst" -C "$tmpdir/in" sparse.bin
validator_require_file "$tmpdir/a.tar.zst"

magic=$(od -An -N4 -tx1 "$tmpdir/a.tar.zst" | tr -d ' \n')
test "$magic" = "28b52ffd"

bsdtar -xf "$tmpdir/a.tar.zst" -C "$tmpdir/out"
validator_require_file "$tmpdir/out/sparse.bin"

dst_size=$(stat -c %s "$tmpdir/out/sparse.bin")
test "$dst_size" = "$src_size" || {
  printf 'sparse file logical size mismatch: src=%s dst=%s\n' "$src_size" "$dst_size" >&2
  exit 1
}

dst_sum=$(sha256sum "$tmpdir/out/sparse.bin" | awk '{print $1}')
test "$src_sum" = "$dst_sum" || {
  printf 'sparse file content sha256 mismatch\n' >&2
  exit 1
}

# Spot-check the trailing data segment survived as written.
tail_bytes=$(tail -c 32 "$tmpdir/out/sparse.bin")
test "$tail_bytes" = "sparse-tail-marker-payload-32by" || {
  printf 'sparse file trailing payload mismatch: %s\n' "$tail_bytes" >&2
  exit 1
}
