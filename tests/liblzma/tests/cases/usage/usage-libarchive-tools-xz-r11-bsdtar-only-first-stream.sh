#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-r11-bsdtar-only-first-stream
# @title: bsdtar reads only the first .xz stream from a concatenated tarball
# @description: Concatenates two independently xz-compressed tarballs into one file and verifies bsdtar -tf lists only the first archive's entries while "xz -dc | bsdtar -tf -" still lists only the first (matching documented bsdtar single-stream behavior).
# @timeout: 60
# @tags: usage, xz, bsdtar
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/d1" "$tmpdir/d2"
printf 'first\n' >"$tmpdir/d1/first.txt"
printf 'second\n' >"$tmpdir/d2/second.txt"

bsdtar -cJf "$tmpdir/t1.tar.xz" -C "$tmpdir/d1" first.txt
bsdtar -cJf "$tmpdir/t2.tar.xz" -C "$tmpdir/d2" second.txt
cat "$tmpdir/t1.tar.xz" "$tmpdir/t2.tar.xz" >"$tmpdir/both.tar.xz"

bsdtar -tf "$tmpdir/both.tar.xz" >"$tmpdir/listing.txt"
listing=$(cat "$tmpdir/listing.txt")
test "$listing" = "first.txt"

xz -dc "$tmpdir/both.tar.xz" | bsdtar -tf - >"$tmpdir/listing-piped.txt"
piped=$(cat "$tmpdir/listing-piped.txt")
test "$piped" = "first.txt"
