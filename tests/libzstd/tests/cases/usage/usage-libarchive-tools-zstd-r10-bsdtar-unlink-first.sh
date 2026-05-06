#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r10-bsdtar-unlink-first
# @title: bsdtar zstd extract -U overwrites pre-existing destination content
# @description: Pre-populates the destination file with stale content then extracts a zstd archive with -U (unlink-first), asserting bsdtar overwrites the stale bytes so the destination sha256 matches the source archive payload.
# @timeout: 180
# @tags: usage, archive, zstd, extract
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in" "$tmpdir/out"
printf 'replacement payload\n' >"$tmpdir/in/note.txt"
src_sum=$(sha256sum "$tmpdir/in/note.txt" | awk '{print $1}')

bsdtar --zstd -cf "$tmpdir/a.tar.zst" -C "$tmpdir/in" note.txt

# Seed the destination with stale content so -U has something to unlink.
printf 'stale-bytes-that-must-be-replaced\n' >"$tmpdir/out/note.txt"

bsdtar -xUf "$tmpdir/a.tar.zst" -C "$tmpdir/out"

dst_sum=$(sha256sum "$tmpdir/out/note.txt" | awk '{print $1}')
test "$src_sum" = "$dst_sum"

# The stale marker must no longer be present in the destination payload.
! grep -Fq 'stale-bytes-that-must-be-replaced' "$tmpdir/out/note.txt"
