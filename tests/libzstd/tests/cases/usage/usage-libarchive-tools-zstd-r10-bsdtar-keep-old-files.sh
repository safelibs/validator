#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r10-bsdtar-keep-old-files
# @title: bsdtar zstd extract -k preserves existing files
# @description: Pre-populates an output file then extracts a zstd archive with -k (keep-old-files), asserting bsdtar leaves the original on-disk content in place rather than overwriting it with the archive payload.
# @timeout: 180
# @tags: usage, archive, zstd, extract
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in" "$tmpdir/out"
printf 'archive content\n' >"$tmpdir/in/note.txt"
bsdtar --zstd -cf "$tmpdir/a.tar.zst" -C "$tmpdir/in" note.txt

# Seed the destination with a different content for the same path.
printf 'preexisting\n' >"$tmpdir/out/note.txt"
src_sum=$(sha256sum "$tmpdir/out/note.txt" | awk '{print $1}')

# bsdtar -k must not overwrite the existing destination file; whether it
# returns non-zero or just warns varies, so assert content preservation.
bsdtar -xkf "$tmpdir/a.tar.zst" -C "$tmpdir/out" 2>"$tmpdir/err" || true

dst_sum=$(sha256sum "$tmpdir/out/note.txt" | awk '{print $1}')
test "$src_sum" = "$dst_sum"
