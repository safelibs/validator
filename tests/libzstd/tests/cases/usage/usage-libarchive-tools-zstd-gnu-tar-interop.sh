#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-gnu-tar-interop
# @title: bsdtar reads zstd archive made by zstd CLI
# @description: Builds a tar with system tar, compresses it with the zstd CLI, then has bsdtar via libzstd extract it and validates payload sha256.
# @timeout: 240
# @tags: usage, archive, zstd, interop
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in" "$tmpdir/out"
printf 'gnu tar interop payload\n' >"$tmpdir/in/payload.txt"

# Stage 1: stock tar produces a plain tar archive.
tar -cf "$tmpdir/a.tar" -C "$tmpdir/in" payload.txt

# Stage 2: zstd CLI compresses it to .tar.zst.
zstd -q -19 -o "$tmpdir/a.tar.zst" "$tmpdir/a.tar"
validator_require_file "$tmpdir/a.tar.zst"

magic=$(od -An -N4 -tx1 "$tmpdir/a.tar.zst" | tr -d ' \n')
test "$magic" = "28b52ffd"

# Stage 3: bsdtar pulls libzstd in to decompress and extract.
bsdtar -xf "$tmpdir/a.tar.zst" -C "$tmpdir/out"

src_sum=$(sha256sum "$tmpdir/in/payload.txt" | awk '{print $1}')
dst_sum=$(sha256sum "$tmpdir/out/payload.txt" | awk '{print $1}')
test "$src_sum" = "$dst_sum"
