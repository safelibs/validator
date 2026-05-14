#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r18-bsdtar-zstd-no-recursion-flat-dir
# @title: bsdtar --zstd --no-recursion archives only the named directory entry, not its contents
# @description: Creates a directory with two files inside and packs only the directory entry into a tar.zst archive with --no-recursion, then lists the archive and asserts only the directory member is present, not the nested files.
# @timeout: 60
# @tags: usage, archive, bsdtar, zstd, no-recursion, r18
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/src"
mkdir -p "$src/dir"
printf 'inner1\n' >"$src/dir/a.txt"
printf 'inner2\n' >"$src/dir/b.txt"

(cd "$src" && bsdtar --zstd --no-recursion -cf "$tmpdir/archive.tar.zst" dir)

bsdtar -tf "$tmpdir/archive.tar.zst" >"$tmpdir/listing.txt"
# Directory entry should appear.
grep -Eq '^dir/?$' "$tmpdir/listing.txt" || {
    echo "expected the 'dir' entry to be archived" >&2
    cat "$tmpdir/listing.txt" >&2
    exit 1
}
# But nested files should NOT.
if grep -Eq 'dir/(a|b)\.txt' "$tmpdir/listing.txt"; then
    echo "expected nested files to be skipped under --no-recursion" >&2
    cat "$tmpdir/listing.txt" >&2
    exit 1
fi
