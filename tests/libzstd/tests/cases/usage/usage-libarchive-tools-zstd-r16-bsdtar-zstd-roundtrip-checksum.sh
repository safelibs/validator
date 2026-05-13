#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r16-bsdtar-zstd-roundtrip-checksum
# @title: bsdtar --zstd creates and extracts a tar.zst archive whose contents byte-match the source tree
# @description: Stages a small file tree, packs it with bsdtar --zstd into a .tar.zst archive, extracts it into a sibling directory, and asserts the SHA-256 of every restored file matches the original — exercising libarchive's --zstd compressor in both create and extract modes.
# @timeout: 120
# @tags: usage, archive, zstd, bsdtar, roundtrip
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/src"
mkdir -p "$src/sub"
python3 -c 'import sys
sys.stdout.buffer.write(b"r16 bsdtar zstd root file content row\n" * 80)' >"$src/root.txt"
python3 -c 'import sys
sys.stdout.buffer.write(b"r16 bsdtar zstd sub file payload row\n" * 60)' >"$src/sub/leaf.txt"

(cd "$tmpdir" && bsdtar --zstd -cf archive.tar.zst -C src .)
validator_require_file "$tmpdir/archive.tar.zst"
file "$tmpdir/archive.tar.zst" | grep -Eq 'Zstandard'

dest="$tmpdir/dest"
mkdir -p "$dest"
bsdtar --zstd -xf "$tmpdir/archive.tar.zst" -C "$dest"

for rel in root.txt sub/leaf.txt; do
    src_sum=$(sha256sum "$src/$rel" | awk '{print $1}')
    dst_sum=$(sha256sum "$dest/$rel" | awk '{print $1}')
    test "$src_sum" = "$dst_sum" || {
        printf 'mismatch on %s: %s vs %s\n' "$rel" "$src_sum" "$dst_sum" >&2
        exit 1
    }
done
