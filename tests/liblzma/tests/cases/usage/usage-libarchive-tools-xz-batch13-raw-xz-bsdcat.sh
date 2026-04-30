#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-batch13-raw-xz-bsdcat
# @title: bsdcat reads raw xz file
# @description: Compresses a deterministic payload with xz(1) into a standalone .xz (no tar) and confirms bsdcat decodes it byte-identically through liblzma.
# @timeout: 180
# @tags: usage, xz, bsdcat
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/work"
python3 -c 'import sys
for i in range(1024):
    sys.stdout.write("raw xz payload %04d ABCDEF\n" % i)' >"$tmpdir/work/payload.bin"
sha_in=$(sha256sum "$tmpdir/work/payload.bin" | awk '{print $1}')

# Plain .xz (no tar wrapper) with -F xz format.
xz -z -F xz -k -c "$tmpdir/work/payload.bin" >"$tmpdir/work/payload.xz"

# .xz magic on the standalone stream
magic_hex=$(head -c 6 "$tmpdir/work/payload.xz" | od -An -tx1 | tr -d ' \n')
test "$magic_hex" = "fd377a585a00"

# bsdcat (libarchive + liblzma) reads the .xz file directly.
bsdcat "$tmpdir/work/payload.xz" >"$tmpdir/work/out.bin"
cmp "$tmpdir/work/payload.bin" "$tmpdir/work/out.bin"
sha_out=$(sha256sum "$tmpdir/work/out.bin" | awk '{print $1}')
test "$sha_in" = "$sha_out"
