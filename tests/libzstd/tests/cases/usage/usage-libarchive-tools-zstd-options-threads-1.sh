#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-options-threads-1
# @title: bsdtar zstd single-thread option
# @description: Creates a zstd-compressed tar with --options 'zstd:threads=1' to force single-threaded encoding and verifies the frame magic plus a sha256 round-trip.
# @timeout: 180
# @tags: usage, archive, zstd
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in" "$tmpdir/out"
printf 'single-thread payload\n' >"$tmpdir/in/payload.txt"

bsdtar --zstd --options 'zstd:threads=1' \
  -cf "$tmpdir/a.tar.zst" -C "$tmpdir/in" payload.txt
validator_require_file "$tmpdir/a.tar.zst"

magic=$(od -An -N4 -tx1 "$tmpdir/a.tar.zst" | tr -d ' \n')
test "$magic" = "28b52ffd"

bsdtar -xf "$tmpdir/a.tar.zst" -C "$tmpdir/out"

src_sum=$(sha256sum "$tmpdir/in/payload.txt" | awk '{print $1}')
dst_sum=$(sha256sum "$tmpdir/out/payload.txt" | awk '{print $1}')
test "$src_sum" = "$dst_sum"
