#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r10-bsdtar-no-xattrs-create
# @title: bsdtar zstd --no-xattrs create round-trip
# @description: Creates a zstd-compressed tar with --no-xattrs to suppress xattr capture (libarchive accepts it regardless of fs xattr support), asserts the zstd magic, and confirms the payload sha256 round-trips through extraction.
# @timeout: 180
# @tags: usage, archive, zstd, xattrs
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in" "$tmpdir/out"
printf 'no-xattrs payload\n' >"$tmpdir/in/plain.txt"
src_sum=$(sha256sum "$tmpdir/in/plain.txt" | awk '{print $1}')

bsdtar --zstd --no-xattrs -cf "$tmpdir/a.tar.zst" -C "$tmpdir/in" plain.txt
validator_require_file "$tmpdir/a.tar.zst"

magic=$(od -An -N4 -tx1 "$tmpdir/a.tar.zst" | tr -d ' \n')
test "$magic" = "28b52ffd"

# Member must round-trip cleanly even with xattr capture disabled.
bsdtar --no-xattrs -xf "$tmpdir/a.tar.zst" -C "$tmpdir/out"
dst_sum=$(sha256sum "$tmpdir/out/plain.txt" | awk '{print $1}')
test "$src_sum" = "$dst_sum"
