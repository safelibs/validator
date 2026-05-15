#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r20-bsdtar-options-level-three-roundtrip
# @title: bsdtar --zstd --options zstd:compression-level=3 roundtrips a member with identical SHA-256
# @description: Builds a tar.zst archive with bsdtar --zstd --options zstd:compression-level=3 and extracts it back, asserting the SHA-256 of the original and extracted payload match byte-for-byte, pinning libarchive's zstd compression-level option passthrough.
# @timeout: 60
# @tags: usage, archive, bsdtar, zstd, level-three, r20
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/src"
mkdir -p "$src"
python3 -c 'import sys
sys.stdout.buffer.write(b"r20 level-three payload\n" * 80)' >"$src/payload.txt"
src_sha=$(sha256sum "$src/payload.txt" | awk '{print $1}')

(cd "$src" && bsdtar --zstd --options 'zstd:compression-level=3' -cf "$tmpdir/out.tar.zst" payload.txt)

dest="$tmpdir/dest"
mkdir -p "$dest"
(cd "$dest" && bsdtar --zstd -xf "$tmpdir/out.tar.zst")

out_sha=$(sha256sum "$dest/payload.txt" | awk '{print $1}')
[[ "$out_sha" == "$src_sha" ]] || { printf 'sha mismatch: src=%s out=%s\n' "$src_sha" "$out_sha" >&2; exit 1; }
