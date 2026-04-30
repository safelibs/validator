#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-batch12-lzma-filter-level6
# @title: bsdtar lzma filter level 6
# @description: Creates a tar.lzma with bsdtar using --lzma at compression-level=6 and verifies legacy LZMA magic plus byte-equal round-trip.
# @timeout: 180
# @tags: usage, archive, lzma
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in" "$tmpdir/out"
printf 'lzma legacy filter payload\n' >"$tmpdir/in/payload.txt"
dd if=/dev/zero of="$tmpdir/in/zeros.bin" bs=1024 count=8 status=none

bsdtar --options 'lzma:compression-level=6' --lzma -cf "$tmpdir/a.tar.lzma" -C "$tmpdir/in" .

# Legacy .lzma stream starts with properties byte 0x5d
first_byte=$(head -c 1 "$tmpdir/a.tar.lzma" | od -An -tx1 | tr -d ' \n')
test "$first_byte" = "5d"

# file(1) classifies legacy LZMA streams
file "$tmpdir/a.tar.lzma" >"$tmpdir/file.txt"
grep -Eqi 'lzma|LZMA' "$tmpdir/file.txt"

bsdtar -xf "$tmpdir/a.tar.lzma" -C "$tmpdir/out"
cmp "$tmpdir/in/payload.txt" "$tmpdir/out/payload.txt"
cmp "$tmpdir/in/zeros.bin" "$tmpdir/out/zeros.bin"
