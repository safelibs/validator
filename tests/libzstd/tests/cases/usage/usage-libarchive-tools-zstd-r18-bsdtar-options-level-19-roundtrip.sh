#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r18-bsdtar-options-level-19-roundtrip
# @title: bsdtar --zstd --options zstd:compression-level=19 round-trips content byte-for-byte
# @description: Packs a deterministic text payload into tar.zst at compression-level 19 via bsdtar, extracts it back to a fresh directory, and asserts the extracted file's SHA-256 matches the source to lock in high-level compression correctness.
# @timeout: 180
# @tags: usage, archive, bsdtar, zstd, options, r18
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/src"
mkdir -p "$src"
python3 -c 'import sys
sys.stdout.buffer.write(b"r18 level19 row\n" * 256)' >"$src/payload.txt"
src_sha=$(sha256sum "$src/payload.txt" | awk '{print $1}')

(cd "$src" && bsdtar --zstd --options 'zstd:compression-level=19' -cf "$tmpdir/archive.tar.zst" payload.txt)
validator_require_file "$tmpdir/archive.tar.zst"

dest="$tmpdir/dest"
mkdir -p "$dest"
(cd "$dest" && bsdtar -xf "$tmpdir/archive.tar.zst")

out_sha=$(sha256sum "$dest/payload.txt" | awk '{print $1}')
[[ "$out_sha" == "$src_sha" ]] || {
    printf 'sha mismatch: src=%s out=%s\n' "$src_sha" "$out_sha" >&2
    exit 1
}
