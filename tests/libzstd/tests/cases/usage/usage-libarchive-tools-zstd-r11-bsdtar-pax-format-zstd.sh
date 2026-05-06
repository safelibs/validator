#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r11-bsdtar-pax-format-zstd
# @title: bsdtar --zstd --format=pax pairs zstd compression with pax tar
# @description: Builds a zstd-compressed pax-format tar containing a long-pathname member exceeding the ustar 100-byte limit and verifies bsdtar reads the pax extended header back to recover the full path on extract.
# @timeout: 180
# @tags: usage, archive, zstd, pax, long-pathname
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Build a >100-byte pathname that ustar cannot represent without pax extension headers.
nested="$tmpdir/in"
suffix=""
for i in 1 2 3 4 5 6 7 8 9 10; do
    suffix="$suffix/segment-name-$i-padding"
    nested="$nested/segment-name-$i-padding"
    mkdir -p "$nested"
done
payload="$nested/long-named-payload-file.txt"
printf 'pax-long-path\n' >"$payload"

# Confirm the relative path within $tmpdir/in exceeds the 100-byte ustar limit.
relpath="${payload#"$tmpdir/in/"}"
test "${#relpath}" -gt 100

bsdtar --zstd --format=pax -cf "$tmpdir/pax.tar.zst" -C "$tmpdir/in" "$relpath"
mkdir -p "$tmpdir/out"
bsdtar -xf "$tmpdir/pax.tar.zst" -C "$tmpdir/out"

[[ -f "$tmpdir/out/$relpath" ]]
diff -q "$payload" "$tmpdir/out/$relpath"
