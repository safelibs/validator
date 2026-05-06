#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-r9-bsdtar-stdin-pipe-create
# @title: bsdtar zstd archive piped from stdin file list
# @description: Pipes filenames into bsdtar via -T - to build a zstd-compressed archive, then extracts and verifies both files appear in the output directory.
# @timeout: 180
# @tags: usage, archive, zstd
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in" "$tmpdir/out"
printf 'first file payload\n' >"$tmpdir/in/one.txt"
printf 'second file payload\n' >"$tmpdir/in/two.txt"

printf 'one.txt\ntwo.txt\n' \
  | bsdtar --zstd -cf "$tmpdir/a.tar.zst" -C "$tmpdir/in" -T -

bsdtar -xf "$tmpdir/a.tar.zst" -C "$tmpdir/out"
diff -q "$tmpdir/in/one.txt" "$tmpdir/out/one.txt"
diff -q "$tmpdir/in/two.txt" "$tmpdir/out/two.txt"
