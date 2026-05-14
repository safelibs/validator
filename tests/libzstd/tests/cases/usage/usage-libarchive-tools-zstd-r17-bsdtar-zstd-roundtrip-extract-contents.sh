#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r17-bsdtar-zstd-roundtrip-extract-contents
# @title: bsdtar --zstd create + extract round-trips file contents byte-for-byte
# @description: Packs two files into tar.zst with bsdtar --zstd, extracts the archive into a fresh directory, and asserts each extracted file's SHA-256 matches the source, locking in the create/extract round-trip through libarchive's zstd-backed format.
# @timeout: 120
# @tags: usage, archive, bsdtar, zstd, roundtrip
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/src"
mkdir -p "$src"
python3 -c 'import sys
sys.stdout.buffer.write(b"r17 roundtrip alpha row\n" * 70)' >"$src/alpha.txt"
python3 -c 'import sys
sys.stdout.buffer.write(b"r17 roundtrip bravo row\n" * 90)' >"$src/bravo.txt"

a_sum=$(sha256sum "$src/alpha.txt" | awk '{print $1}')
b_sum=$(sha256sum "$src/bravo.txt" | awk '{print $1}')

(cd "$src" && bsdtar --zstd -cf "$tmpdir/archive.tar.zst" alpha.txt bravo.txt)
validator_require_file "$tmpdir/archive.tar.zst"

dest="$tmpdir/dest"
mkdir -p "$dest"
(cd "$dest" && bsdtar -xf "$tmpdir/archive.tar.zst")

a_out=$(sha256sum "$dest/alpha.txt" | awk '{print $1}')
b_out=$(sha256sum "$dest/bravo.txt" | awk '{print $1}')

[[ "$a_out" == "$a_sum" ]] || { printf 'alpha sha mismatch\n' >&2; exit 1; }
[[ "$b_out" == "$b_sum" ]] || { printf 'bravo sha mismatch\n' >&2; exit 1; }
