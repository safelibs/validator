#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-batch19-keep-old-files-extract
# @title: bsdtar -kxJf preserves existing target file
# @description: Pre-populates the extract directory with a sentinel file, then extracts a .tar.xz that contains a same-named entry with bsdtar -k and confirms the existing file is preserved while other entries are decompressed via liblzma.
# @timeout: 180
# @tags: usage, archive, xz, extract, keep
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/src" "$tmpdir/out"
printf 'archive copy of overlap\n' >"$tmpdir/src/overlap.txt"
printf 'archive only entry\n' >"$tmpdir/src/extra.txt"

bsdtar -cJf "$tmpdir/a.tar.xz" -C "$tmpdir/src" overlap.txt extra.txt

# Pre-populate destination with a different content for the overlapping name.
printf 'pre-existing sentinel\n' >"$tmpdir/out/overlap.txt"
sentinel_sha=$(sha256sum "$tmpdir/out/overlap.txt" | awk '{print $1}')

# -k tells bsdtar to keep existing files: the overlapping target must NOT be
# overwritten, but the non-conflicting entry must still be extracted.
bsdtar -kxJf "$tmpdir/a.tar.xz" -C "$tmpdir/out" 2>"$tmpdir/err.log" || true

# Sentinel content survived.
post_sha=$(sha256sum "$tmpdir/out/overlap.txt" | awk '{print $1}')
test "$sentinel_sha" = "$post_sha"

# Non-conflicting entry was extracted via liblzma.
[[ -f "$tmpdir/out/extra.txt" ]]
cmp "$tmpdir/src/extra.txt" "$tmpdir/out/extra.txt"
