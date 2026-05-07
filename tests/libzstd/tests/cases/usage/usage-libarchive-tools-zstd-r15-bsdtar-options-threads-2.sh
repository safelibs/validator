#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r15-bsdtar-options-threads-2
# @title: bsdtar --options=zstd:threads=2 produces a parallel-compressed tar that decodes cleanly
# @description: Builds a zstd-compressed tar with bsdtar --options 'zstd:threads=2' so the multi-threaded compressor path is exercised, asserts the archive carries the zstd frame magic, and confirms extraction recovers the source files byte-for-byte.
# @timeout: 60
# @tags: usage, archive, bsdtar, options, threads
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/src"
mkdir -p "$src"
python3 -c 'import sys, os
for i in range(4):
    with open(os.path.join(sys.argv[1], f"f{i}.txt"), "wb") as fh:
        fh.write((b"r15 threads=2 row %d\n" % i) * 200)' "$src"

archive="$tmpdir/out.tar.zst"
bsdtar --options 'zstd:threads=2' --zstd -cf "$archive" -C "$src" .
validator_require_file "$archive"

magic=$(od -An -N4 -tx1 "$archive" | tr -d ' \n')
test "$magic" = "28b52ffd"

dest="$tmpdir/dest"
mkdir -p "$dest"
bsdtar -xf "$archive" -C "$dest"
for i in 0 1 2 3; do
    src_sum=$(sha256sum "$src/f$i.txt" | awk '{print $1}')
    dst_sum=$(sha256sum "$dest/f$i.txt" | awk '{print $1}')
    [[ "$src_sum" == "$dst_sum" ]] || {
        printf 'mismatch at f%d.txt\n' "$i" >&2
        exit 1
    }
done
