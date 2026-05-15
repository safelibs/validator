#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r19-bsdtar-tvf-shows-size-column
# @title: bsdtar -tvf on a tar.zst lists the member's byte size in the verbose output
# @description: Packs a deterministic 384-byte file into a tar.zst, runs bsdtar -tvf on the archive, and asserts the verbose listing line contains the literal token '384' for the member size to confirm libarchive's size column rendering.
# @timeout: 60
# @tags: usage, archive, bsdtar, zstd, tvf, r19
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/src"
mkdir -p "$src"
python3 -c 'import sys
sys.stdout.buffer.write(b"r19tvfsize\n" * 32)' >"$src/sized.txt"  # 11*32 = 352? recompute
# Make exactly 384 bytes deterministically.
python3 -c 'import sys; sys.stdout.buffer.write(b"x" * 384)' >"$src/sized.txt"
size=$(stat -c '%s' "$src/sized.txt")
[[ "$size" == "384" ]] || { printf 'expected source to be 384 bytes, got %s\n' "$size" >&2; exit 1; }

(cd "$src" && bsdtar --zstd -cf "$tmpdir/archive.tar.zst" sized.txt)
bsdtar -tvf "$tmpdir/archive.tar.zst" >"$tmpdir/listing.txt"
grep -wq '384' "$tmpdir/listing.txt" || {
    echo "expected '384' size token in verbose listing" >&2
    cat "$tmpdir/listing.txt" >&2
    exit 1
}
