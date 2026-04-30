#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-options-comma-multi
# @title: bsdtar zstd multiple --options separated by commas
# @description: Creates a zstd-compressed tar with two zstd writer options joined into a single comma-separated --options value (compression-level=5,zstd:long=24) and verifies the resulting archive round-trips byte-for-byte.
# @timeout: 240
# @tags: usage, archive, zstd, options
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in" "$tmpdir/out"
printf 'comma-options payload\n' >"$tmpdir/in/payload.txt"
src_sum=$(sha256sum "$tmpdir/in/payload.txt" | awk '{print $1}')

bsdtar --zstd \
  --options 'zstd:compression-level=5,zstd:long=24' \
  -cf "$tmpdir/a.tar.zst" -C "$tmpdir/in" payload.txt
validator_require_file "$tmpdir/a.tar.zst"

magic=$(od -An -N4 -tx1 "$tmpdir/a.tar.zst" | tr -d ' \n')
test "$magic" = "28b52ffd"

zstd -tq "$tmpdir/a.tar.zst"

bsdtar -xf "$tmpdir/a.tar.zst" -C "$tmpdir/out"
validator_require_file "$tmpdir/out/payload.txt"
dst_sum=$(sha256sum "$tmpdir/out/payload.txt" | awk '{print $1}')
test "$src_sum" = "$dst_sum"
