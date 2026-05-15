#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r20-bsdtar-extract-preserves-file-size
# @title: bsdtar --zstd roundtrip preserves the exact byte size of an extracted member
# @description: Builds a tar.zst archive containing payload.bin of a fixed 8192-byte size, extracts it into a fresh directory via bsdtar --zstd -xf, and asserts the extracted file is exactly 8192 bytes long, pinning the libarchive zstd reader's whole-member integrity.
# @timeout: 60
# @tags: usage, archive, bsdtar, zstd, size, r20
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/src"
mkdir -p "$src"
# Generate a deterministic 8192-byte payload.
python3 -c 'import sys; sys.stdout.buffer.write(bytes(i & 0xff for i in range(8192)))' >"$src/payload.bin"

(cd "$src" && bsdtar --zstd -cf "$tmpdir/out.tar.zst" payload.bin)

dest="$tmpdir/dest"
mkdir -p "$dest"
(cd "$dest" && bsdtar --zstd -xf "$tmpdir/out.tar.zst")

size=$(stat -c %s "$dest/payload.bin")
[[ "$size" == "8192" ]] || { printf 'expected size 8192, got %s\n' "$size" >&2; exit 1; }
