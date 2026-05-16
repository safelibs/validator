#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-r21-bsdtar-cf-zstd-vs-xz-distinct-magic
# @title: bsdtar tar.xz and tar.lzma archives carry distinct file-format magic prefixes
# @description: Creates the same tar contents with --xz then with --lzma via bsdtar and asserts the first 6 bytes differ between formats (xz: FD 37 7A 58 5A 00; lzma: header begins with 5D 00 00), pinning that liblzma emits format-distinct stream prefixes.
# @timeout: 60
# @tags: usage, bsdtar, xz, lzma, magic, r21
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/src"
printf 'payload\n' >"$tmpdir/src/p.txt"

bsdtar --xz -cf "$tmpdir/a.tar.xz" -C "$tmpdir/src" p.txt
bsdtar --lzma -cf "$tmpdir/b.tar.lzma" -C "$tmpdir/src" p.txt

python3 - "$tmpdir/a.tar.xz" "$tmpdir/b.tar.lzma" <<'PY'
import sys
xz = open(sys.argv[1], 'rb').read(6)
lzma = open(sys.argv[2], 'rb').read(6)
assert xz == b'\xfd7zXZ\x00', xz.hex()
assert lzma[0] == 0x5d, lzma.hex()
assert xz != lzma
PY
