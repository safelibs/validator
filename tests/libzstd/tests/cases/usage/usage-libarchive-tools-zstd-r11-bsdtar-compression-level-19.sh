#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r11-bsdtar-compression-level-19
# @title: bsdtar --zstd compression-level 19 produces valid frame and round-trips
# @description: Compresses a 200-line repeating payload with --options 'zstd:compression-level=19' and verifies the output starts with the zstd magic, --list reports a single frame, and extraction reproduces the input byte-for-byte.
# @timeout: 240
# @tags: usage, archive, zstd, compression-level
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in" "$tmpdir/out"
{ for i in $(seq 1 200); do printf 'compressed payload line %d\n' "$i"; done; } >"$tmpdir/in/repeat.txt"

bsdtar --zstd --options 'zstd:compression-level=19' \
    -cf "$tmpdir/c19.tar.zst" -C "$tmpdir/in" repeat.txt

magic=$(od -An -N4 -tx1 "$tmpdir/c19.tar.zst" | tr -d ' \n')
test "$magic" = "28b52ffd"

zstd --list "$tmpdir/c19.tar.zst" >"$tmpdir/listing"
grep -E '^[[:space:]]+1[[:space:]]+0' "$tmpdir/listing" >/dev/null

bsdtar -xf "$tmpdir/c19.tar.zst" -C "$tmpdir/out"
diff -q "$tmpdir/in/repeat.txt" "$tmpdir/out/repeat.txt"
