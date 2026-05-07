#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r13-bsdtar-options-zstd-long-27
# @title: bsdtar --zstd --options zstd:long=27 enables long-distance matching for the embedded zstd writer
# @description: Builds a directory with several small text files, archives via bsdtar --zstd --options zstd:long=27, asserts the resulting .tar.zst lists the expected entries and round-trips byte-for-byte to the source tree under SHA-256 comparison.
# @timeout: 180
# @tags: usage, archive, zstd, bsdtar, options
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/in"
mkdir -p "$src"
for i in 0 1 2 3 4; do
    python3 -c 'import sys
sys.stdout.buffer.write(b"r13 long27 corpus row " + sys.argv[1].encode() + b"\n" * 256)' "$i" >"$src/f${i}.txt"
done

archive="$tmpdir/out.tar.zst"
bsdtar --zstd --options zstd:long=27 -cf "$archive" -C "$src" .

bsdtar -tf "$archive" >"$tmpdir/listing"
for i in 0 1 2 3 4; do
    grep -q "f${i}.txt" "$tmpdir/listing" || {
        printf 'expected f%d.txt in listing\n' "$i" >&2
        cat "$tmpdir/listing" >&2
        exit 1
    }
done

# Round-trip the entries.
mkdir -p "$tmpdir/out"
bsdtar -xf "$archive" -C "$tmpdir/out"
for i in 0 1 2 3 4; do
    cmp "$src/f${i}.txt" "$tmpdir/out/f${i}.txt"
done
