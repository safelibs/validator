#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-batch19-size-delta-xz-vs-gz
# @title: bsdtar xz smaller than gzip on repetitive input
# @description: Builds a deterministic repetitive payload, compresses it both as .tar.xz and .tar.gz with bsdtar, and asserts the xz output is strictly smaller and round-trips byte-identically through liblzma.
# @timeout: 180
# @tags: usage, archive, xz, gzip
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/src" "$tmpdir/out"
python3 -c 'import sys
for i in range(8000):
    sys.stdout.write("repeating row %04d alpha beta gamma delta epsilon\n" % (i % 16))' \
  >"$tmpdir/src/payload.txt"

src_sha=$(sha256sum "$tmpdir/src/payload.txt" | awk '{print $1}')

bsdtar -cJf "$tmpdir/a.tar.xz" -C "$tmpdir/src" payload.txt
bsdtar -czf "$tmpdir/a.tar.gz" -C "$tmpdir/src" payload.txt

xz_size=$(stat -c '%s' "$tmpdir/a.tar.xz")
gz_size=$(stat -c '%s' "$tmpdir/a.tar.gz")

# Repetitive input compresses far better with LZMA2 than with deflate.
test "$xz_size" -lt "$gz_size"

# .xz magic
magic_hex=$(head -c 6 "$tmpdir/a.tar.xz" | od -An -tx1 | tr -d ' \n')
test "$magic_hex" = "fd377a585a00"

# .gz magic
gz_magic=$(head -c 2 "$tmpdir/a.tar.gz" | od -An -tx1 | tr -d ' \n')
test "$gz_magic" = "1f8b"

bsdtar -xf "$tmpdir/a.tar.xz" -C "$tmpdir/out"
out_sha=$(sha256sum "$tmpdir/out/payload.txt" | awk '{print $1}')
test "$src_sha" = "$out_sha"
