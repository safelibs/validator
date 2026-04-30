#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-bsdtar-large-directory-50-files
# @title: bsdtar --zstd over a 50-file directory tree
# @description: Builds a directory of 50 distinct text files, archives the whole tree with bsdtar --zstd, extracts it into a fresh location, and asserts every member round-trips with matching sha256.
# @timeout: 300
# @tags: usage, archive, zstd, bsdtar
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in" "$tmpdir/out"

# Build 50 distinct files. Avoid yes|head; use a deterministic for-loop.
i=1
while [ "$i" -le 50 ]; do
  printf 'file %02d payload line one\nfile %02d payload line two\n' "$i" "$i" \
    >"$tmpdir/in/file-$(printf '%02d' "$i").txt"
  i=$((i + 1))
done

count_in=$(find "$tmpdir/in" -maxdepth 1 -type f -name 'file-*.txt' | wc -l)
test "$count_in" -eq 50

( cd "$tmpdir/in" && sha256sum file-*.txt ) >"$tmpdir/in.sums"

bsdtar --zstd -cf "$tmpdir/a.tar.zst" -C "$tmpdir/in" .
validator_require_file "$tmpdir/a.tar.zst"

magic=$(od -An -N4 -tx1 "$tmpdir/a.tar.zst" | tr -d ' \n')
test "$magic" = "28b52ffd"

zstd -tq "$tmpdir/a.tar.zst"

bsdtar -xf "$tmpdir/a.tar.zst" -C "$tmpdir/out"

count_out=$(find "$tmpdir/out" -maxdepth 1 -type f -name 'file-*.txt' | wc -l)
test "$count_out" -eq 50

( cd "$tmpdir/out" && sha256sum file-*.txt ) >"$tmpdir/out.sums"
cmp "$tmpdir/in.sums" "$tmpdir/out.sums"
