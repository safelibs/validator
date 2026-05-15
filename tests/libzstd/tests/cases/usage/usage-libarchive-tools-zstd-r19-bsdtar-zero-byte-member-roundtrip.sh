#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r19-bsdtar-zero-byte-member-roundtrip
# @title: bsdtar tar.zst archives a zero-byte file and restores it with size 0 on extract
# @description: Creates an empty file via touch, packs it into a tar.zst archive with bsdtar --zstd -cf, extracts the archive to a fresh directory, and asserts the extracted file exists and reports zero bytes — pinning the libarchive zero-length member roundtrip path.
# @timeout: 60
# @tags: usage, archive, bsdtar, zstd, zero-byte, r19
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/src"
mkdir -p "$src"
: >"$src/empty.bin"
[[ ! -s "$src/empty.bin" ]] || { echo "expected source to be zero bytes" >&2; exit 1; }

(cd "$src" && bsdtar --zstd -cf "$tmpdir/archive.tar.zst" empty.bin)
validator_require_file "$tmpdir/archive.tar.zst"

dest="$tmpdir/dest"
mkdir -p "$dest"
(cd "$dest" && bsdtar -xf "$tmpdir/archive.tar.zst")
validator_require_file "$dest/empty.bin"

size=$(stat -c '%s' "$dest/empty.bin")
[[ "$size" == "0" ]] || { printf 'expected size 0, got %s\n' "$size" >&2; exit 1; }
