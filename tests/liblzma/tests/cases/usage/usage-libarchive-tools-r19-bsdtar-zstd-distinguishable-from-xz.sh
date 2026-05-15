#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-r19-bsdtar-zstd-distinguishable-from-xz
# @title: bsdtar produces distinct magic bytes for xz vs zstd tarballs of the same payload
# @description: Creates the same one-file tarball twice via bsdtar -acf using .tar.xz and .tar.zst suffixes, then asserts the first byte of each archive differs (xz starts 0xFD, zstd starts 0x28), pinning libarchive's filter-by-extension dispatch.
# @timeout: 60
# @tags: usage, bsdtar, xz, zstd, magic, r19
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir "$tmpdir/src"
printf 'r19 distinguishable payload\n' >"$tmpdir/src/data.txt"

(cd "$tmpdir/src" && bsdtar -acf "$tmpdir/out.tar.xz" data.txt)
(cd "$tmpdir/src" && bsdtar -acf "$tmpdir/out.tar.zst" data.txt)

xz_byte=$(head -c1 "$tmpdir/out.tar.xz" | od -An -tx1 | tr -d ' \n')
zst_byte=$(head -c1 "$tmpdir/out.tar.zst" | od -An -tx1 | tr -d ' \n')

[[ "$xz_byte" == "fd" ]] || { printf 'unexpected xz magic byte: %s\n' "$xz_byte" >&2; exit 1; }
[[ "$zst_byte" == "28" ]] || { printf 'unexpected zstd magic byte: %s\n' "$zst_byte" >&2; exit 1; }
[[ "$xz_byte" != "$zst_byte" ]]
