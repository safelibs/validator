#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-options-checksum-flag
# @title: bsdtar zstd compression-level option round-trip
# @description: Creates a zstd-compressed tar with an explicit zstd:compression-level option and verifies the frame magic and a sha256 round-trip.
# @timeout: 180
# @tags: usage, archive, zstd
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in" "$tmpdir/out"
printf 'compression-level option payload\n' >"$tmpdir/in/payload.txt"

# `zstd:checksum` is not a recognized libarchive option on Ubuntu 24.04
# (bsdtar 3.7.x). `zstd:compression-level=N` is the canonical knob the
# libarchive tools expose for the zstd writer module.
bsdtar --zstd --options 'zstd:compression-level=10' \
  -cf "$tmpdir/a.tar.zst" -C "$tmpdir/in" payload.txt
validator_require_file "$tmpdir/a.tar.zst"

magic=$(od -An -N4 -tx1 "$tmpdir/a.tar.zst" | tr -d ' \n')
test "$magic" = "28b52ffd"

bsdtar -xf "$tmpdir/a.tar.zst" -C "$tmpdir/out"

src_sum=$(sha256sum "$tmpdir/in/payload.txt" | awk '{print $1}')
dst_sum=$(sha256sum "$tmpdir/out/payload.txt" | awk '{print $1}')
test "$src_sum" = "$dst_sum"
