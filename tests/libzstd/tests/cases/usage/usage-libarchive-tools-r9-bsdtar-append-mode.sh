#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-r9-bsdtar-append-mode
# @title: bsdtar zstd uncompressed-then-compressed pipeline
# @description: Builds a plain tar, then re-encodes through zstd via bsdtar --zstd to produce a zstd-compressed tar, and verifies the resulting archive lists the original member.
# @timeout: 180
# @tags: usage, archive, zstd
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in"
printf 'original payload\n' >"$tmpdir/in/orig.txt"

bsdtar -cf "$tmpdir/plain.tar" -C "$tmpdir/in" orig.txt

# Pipe-decode plain tar then re-encode with zstd.
bsdtar -xf "$tmpdir/plain.tar" -C "$tmpdir/in" 2>/dev/null || true
bsdtar --zstd -cf "$tmpdir/again.tar.zst" -C "$tmpdir/in" orig.txt

bsdtar -tf "$tmpdir/again.tar.zst" >"$tmpdir/list"
validator_assert_contains "$tmpdir/list" 'orig.txt'

# Decoder must restore original bytes.
mkdir -p "$tmpdir/out"
bsdtar -xf "$tmpdir/again.tar.zst" -C "$tmpdir/out"
diff -q "$tmpdir/in/orig.txt" "$tmpdir/out/orig.txt"
