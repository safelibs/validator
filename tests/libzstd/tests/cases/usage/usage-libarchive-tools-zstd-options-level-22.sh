#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-options-level-22
# @title: bsdtar zstd compression-level 22
# @description: Creates a zstd-compressed tar at the maximum --options zstd:compression-level=22 and verifies round-trip integrity.
# @timeout: 600
# @tags: usage, archive, zstd
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in" "$tmpdir/out"
printf 'ultra payload\n' >"$tmpdir/in/payload.txt"

bsdtar --zstd --options 'zstd:compression-level=22' \
  -cf "$tmpdir/a.tar.zst" -C "$tmpdir/in" payload.txt
validator_require_file "$tmpdir/a.tar.zst"

magic=$(od -An -N4 -tx1 "$tmpdir/a.tar.zst" | tr -d ' \n')
test "$magic" = "28b52ffd"

bsdtar -xf "$tmpdir/a.tar.zst" -C "$tmpdir/out"
validator_assert_contains "$tmpdir/out/payload.txt" 'ultra payload'

src_sum=$(sha256sum "$tmpdir/in/payload.txt" | awk '{print $1}')
dst_sum=$(sha256sum "$tmpdir/out/payload.txt" | awk '{print $1}')
test "$src_sum" = "$dst_sum"
