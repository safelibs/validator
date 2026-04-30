#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-batch15-options-level2-roundtrip
# @title: bsdtar xz compression-level=2 round-trip
# @description: Compresses a payload with --options xz:compression-level=2, confirms the output is a well-formed xz stream smaller than the source, and round-trips byte-identical content back through bsdtar.
# @timeout: 180
# @tags: usage, archive, xz
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in" "$tmpdir/out"
# Highly compressible body so even level 2 visibly shrinks the archive.
python3 -c 'import sys
for _ in range(8192):
    sys.stdout.write("level two compressible row XXXXXXXXXXXXXXXX\n")' \
  >"$tmpdir/in/payload.txt"

src_size=$(stat -c %s "$tmpdir/in/payload.txt")
src_sha=$(sha256sum "$tmpdir/in/payload.txt" | awk '{print $1}')

bsdtar --options 'xz:compression-level=2' \
  -cJf "$tmpdir/a.tar.xz" -C "$tmpdir/in" payload.txt

# .xz magic.
magic_hex=$(head -c 6 "$tmpdir/a.tar.xz" | od -An -tx1 | tr -d ' \n')
test "$magic_hex" = "fd377a585a00"

# A non-empty compressed archive that is meaningfully smaller than the source.
arc_size=$(stat -c %s "$tmpdir/a.tar.xz")
test "$arc_size" -gt 0
test "$arc_size" -lt "$src_size"

# Round-trip: extracted content must be byte-identical to the source.
bsdtar -xf "$tmpdir/a.tar.xz" -C "$tmpdir/out"
out_sha=$(sha256sum "$tmpdir/out/payload.txt" | awk '{print $1}')
test "$src_sha" = "$out_sha"
