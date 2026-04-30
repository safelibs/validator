#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-batch12-bsdcat-xz-file
# @title: bsdcat reads xz file
# @description: Compresses a deterministic payload with xz(1) and confirms bsdcat decompresses it byte-identically through liblzma.
# @timeout: 180
# @tags: usage, xz, bsdcat
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Build a deterministic payload of mixed text + binary content.
{
  printf 'bsdcat header line\n'
  for i in $(seq 1 64); do
    printf 'row %03d alpha beta gamma\n' "$i"
  done
} >"$tmpdir/payload.bin"
dd if=/dev/zero bs=512 count=4 status=none >>"$tmpdir/payload.bin"

xz -z -k -c "$tmpdir/payload.bin" >"$tmpdir/payload.xz"

# Confirm .xz magic
magic_hex=$(head -c 6 "$tmpdir/payload.xz" | od -An -tx1 | tr -d ' \n')
test "$magic_hex" = "fd377a585a00"

bsdcat "$tmpdir/payload.xz" >"$tmpdir/out.bin"

cmp "$tmpdir/payload.bin" "$tmpdir/out.bin"
sha_in=$(sha256sum "$tmpdir/payload.bin" | awk '{print $1}')
sha_out=$(sha256sum "$tmpdir/out.bin" | awk '{print $1}')
test "$sha_in" = "$sha_out"
