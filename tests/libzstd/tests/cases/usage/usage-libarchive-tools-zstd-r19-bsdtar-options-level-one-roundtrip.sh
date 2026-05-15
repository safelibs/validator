#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r19-bsdtar-options-level-one-roundtrip
# @title: bsdtar --zstd --options zstd:compression-level=1 produces a valid tar.zst that round-trips
# @description: Packs a deterministic payload into tar.zst at the lowest zstd compression level (1), extracts back into a fresh directory, and verifies the extracted file's SHA-256 matches the source — pinning libarchive's lowest-level zstd encoder roundtrip.
# @timeout: 60
# @tags: usage, archive, bsdtar, zstd, level-1, r19
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/src"
mkdir -p "$src"
python3 -c 'import sys; sys.stdout.buffer.write(b"r19 level1 row\n" * 128)' >"$src/payload.txt"
src_sha=$(sha256sum "$src/payload.txt" | awk '{print $1}')

(cd "$src" && bsdtar --zstd --options 'zstd:compression-level=1' -cf "$tmpdir/archive.tar.zst" payload.txt)
validator_require_file "$tmpdir/archive.tar.zst"

# zstd magic prefix.
magic=$(od -An -N4 -tx1 "$tmpdir/archive.tar.zst" | tr -d ' \n')
[[ "$magic" == "28b52ffd" ]] || { printf 'unexpected zstd magic: %s\n' "$magic" >&2; exit 1; }

dest="$tmpdir/dest"
mkdir -p "$dest"
(cd "$dest" && bsdtar -xf "$tmpdir/archive.tar.zst")

out_sha=$(sha256sum "$dest/payload.txt" | awk '{print $1}')
[[ "$out_sha" == "$src_sha" ]] || { printf 'sha mismatch: src=%s out=%s\n' "$src_sha" "$out_sha" >&2; exit 1; }
