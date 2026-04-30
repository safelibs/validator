#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-options-level-3
# @title: bsdtar zstd compression-level 3
# @description: Creates a zstd-compressed tar with --options zstd:compression-level=3 and round-trips the payload back.
# @timeout: 180
# @tags: usage, archive, zstd
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in" "$tmpdir/out"
printf 'level-3 payload\n' >"$tmpdir/in/payload.txt"

bsdtar --zstd --options 'zstd:compression-level=3' \
  -cf "$tmpdir/a.tar.zst" -C "$tmpdir/in" payload.txt
validator_require_file "$tmpdir/a.tar.zst"

magic=$(od -An -N4 -tx1 "$tmpdir/a.tar.zst" | tr -d ' \n')
test "$magic" = "28b52ffd"

bsdtar -xf "$tmpdir/a.tar.zst" -C "$tmpdir/out"
validator_assert_contains "$tmpdir/out/payload.txt" 'level-3 payload'
