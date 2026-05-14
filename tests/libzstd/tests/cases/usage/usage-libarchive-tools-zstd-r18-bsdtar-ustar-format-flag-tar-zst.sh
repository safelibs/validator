#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r18-bsdtar-ustar-format-flag-tar-zst
# @title: bsdtar --zstd --format ustar packs a tar.zst archive and round-trips contents
# @description: Creates a tar.zst archive forcing the inner tar format to ustar via --format ustar, extracts it back into a clean directory, and verifies the extracted file's SHA-256 matches the source to lock in libarchive's ustar+zstd combination.
# @timeout: 60
# @tags: usage, archive, bsdtar, zstd, ustar, r18
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/src"
mkdir -p "$src"
python3 -c 'import sys
sys.stdout.buffer.write(b"r18 ustar+zstd row\n" * 96)' >"$src/u.txt"
src_sha=$(sha256sum "$src/u.txt" | awk '{print $1}')

(cd "$src" && bsdtar --zstd --format ustar -cf "$tmpdir/archive.tar.zst" u.txt)
validator_require_file "$tmpdir/archive.tar.zst"

dest="$tmpdir/dest"
mkdir -p "$dest"
(cd "$dest" && bsdtar -xf "$tmpdir/archive.tar.zst")

out_sha=$(sha256sum "$dest/u.txt" | awk '{print $1}')
[[ "$out_sha" == "$src_sha" ]] || {
    printf 'sha mismatch: src=%s out=%s\n' "$src_sha" "$out_sha" >&2
    exit 1
}
