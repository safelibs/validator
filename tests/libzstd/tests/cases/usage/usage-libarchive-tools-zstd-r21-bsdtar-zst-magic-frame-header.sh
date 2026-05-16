#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r21-bsdtar-zst-magic-frame-header
# @title: bsdtar --zstd output begins with the zstd frame magic 0x28b52ffd
# @description: Creates a tar.zst archive with bsdtar --zstd and asserts the first four bytes equal the zstd frame magic number 28 b5 2f fd (little-endian 0xFD2FB528) — pinning libarchive's zstd frame header emission on Ubuntu 24.04.
# @timeout: 60
# @tags: usage, archive, bsdtar, zstd, magic, frame-header, r21
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src=$tmpdir/src
mkdir -p "$src"
printf 'magic-header-check-r21\n' >"$src/payload.txt"

bsdtar --zstd -cf "$tmpdir/a.tar.zst" -C "$tmpdir" src

magic=$(head -c 4 "$tmpdir/a.tar.zst" | od -An -tx1 | tr -d ' ' | tr -d '\n')
[[ "$magic" == "28b52ffd" ]] || { printf 'expected zstd frame magic 28b52ffd, got %s\n' "$magic" >&2; exit 1; }
