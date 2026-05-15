#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r19-bsdtar-list-directory-entry-trailing-slash
# @title: bsdtar -tf prints directory members in a tar.zst with a trailing slash
# @description: Packs a directory containing one file into a tar.zst archive, runs bsdtar -tf on it, and asserts the directory member appears with a trailing '/' in the listing — pinning the libarchive directory-entry rendering for tar.zst archives.
# @timeout: 60
# @tags: usage, archive, bsdtar, zstd, directory, r19
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/src"
mkdir -p "$src/subdir"
printf 'leaf\n' >"$src/subdir/leaf.txt"

(cd "$src" && bsdtar --zstd -cf "$tmpdir/archive.tar.zst" subdir)
bsdtar -tf "$tmpdir/archive.tar.zst" >"$tmpdir/listing.txt"

grep -Eq '^subdir/$' "$tmpdir/listing.txt" || {
    echo "expected directory entry with trailing slash" >&2
    cat "$tmpdir/listing.txt" >&2
    exit 1
}
grep -Eq '^subdir/leaf\.txt$' "$tmpdir/listing.txt"
