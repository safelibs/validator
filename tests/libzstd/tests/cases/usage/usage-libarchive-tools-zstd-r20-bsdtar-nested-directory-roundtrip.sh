#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r20-bsdtar-nested-directory-roundtrip
# @title: bsdtar --zstd roundtrip preserves a two-level nested directory layout
# @description: Creates a src/a/b/payload.txt three-level layout, archives src via bsdtar --zstd, extracts it into a fresh destination, and asserts the destination contains the file at the same relative path with byte-identical contents, pinning libarchive's nested-directory traversal under zstd.
# @timeout: 60
# @tags: usage, archive, bsdtar, zstd, nested, r20
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/src"
mkdir -p "$src/a/b"
echo "r20 nested payload" >"$src/a/b/payload.txt"
src_sha=$(sha256sum "$src/a/b/payload.txt" | awk '{print $1}')

(cd "$tmpdir" && bsdtar --zstd -cf out.tar.zst src)

dest="$tmpdir/dest"
mkdir -p "$dest"
(cd "$dest" && bsdtar --zstd -xf "$tmpdir/out.tar.zst")

validator_require_file "$dest/src/a/b/payload.txt"
out_sha=$(sha256sum "$dest/src/a/b/payload.txt" | awk '{print $1}')
[[ "$out_sha" == "$src_sha" ]] || { printf 'sha mismatch: src=%s out=%s\n' "$src_sha" "$out_sha" >&2; exit 1; }
