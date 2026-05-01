#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-batch19-bsdcat-lzma-legacy
# @title: bsdcat reads legacy .lzma file
# @description: Compresses a deterministic payload with xz -F lzma to produce a legacy .lzma stream and verifies bsdcat decodes it byte-identically through liblzma's legacy LZMA reader.
# @timeout: 180
# @tags: usage, lzma, bsdcat
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Mixed text + zero bytes so the round-trip exercises a non-trivial buffer.
{
  for i in $(seq 1 96); do
    printf 'legacy lzma row %03d alpha beta gamma\n' "$i"
  done
  dd if=/dev/zero bs=128 count=4 status=none
} >"$tmpdir/payload.bin"

src_sha=$(sha256sum "$tmpdir/payload.bin" | awk '{print $1}')

xz -F lzma -z -c "$tmpdir/payload.bin" >"$tmpdir/payload.lzma"

# Legacy .lzma magic begins 5d 00 00 (properties byte + dict size LSBs).
magic_hex=$(head -c 3 "$tmpdir/payload.lzma" | od -An -tx1 | tr -d ' \n')
test "$magic_hex" = "5d0000"

bsdcat "$tmpdir/payload.lzma" >"$tmpdir/out.bin"

cmp "$tmpdir/payload.bin" "$tmpdir/out.bin"
out_sha=$(sha256sum "$tmpdir/out.bin" | awk '{print $1}')
test "$src_sha" = "$out_sha"
