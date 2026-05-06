#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-r10-check-crc32
# @title: xz --check=crc32 integrity check
# @description: Compresses a payload with xz --check=crc32 and confirms xz --robot --list reports CRC32 in the integrity-check column, then round-trips via bsdtar to ensure liblzma decodes a CRC32-checked stream.
# @timeout: 180
# @tags: usage, archive, xz, integrity
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/src" "$tmpdir/out"
printf 'crc32 check payload\nrow two\nrow three\n' >"$tmpdir/src/payload.txt"
src_sha=$(sha256sum "$tmpdir/src/payload.txt" | awk '{print $1}')

bsdtar -cf "$tmpdir/plain.tar" -C "$tmpdir/src" payload.txt
xz --check=crc32 -z -c "$tmpdir/plain.tar" >"$tmpdir/plain.tar.xz"

magic_hex=$(head -c 6 "$tmpdir/plain.tar.xz" | od -An -tx1 | tr -d ' \n')
test "$magic_hex" = "fd377a585a00"

xz --robot --list "$tmpdir/plain.tar.xz" >"$tmpdir/list.txt"
check_field=$(awk '$1=="totals"{print $7}' "$tmpdir/list.txt")
test "$check_field" = "CRC32"

bsdtar -xf "$tmpdir/plain.tar.xz" -C "$tmpdir/out"
out_sha=$(sha256sum "$tmpdir/out/payload.txt" | awk '{print $1}')
test "$src_sha" = "$out_sha"
