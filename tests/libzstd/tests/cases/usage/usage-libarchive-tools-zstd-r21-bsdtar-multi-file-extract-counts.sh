#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r21-bsdtar-multi-file-extract-counts
# @title: bsdtar --zstd archives five distinct files and extracts all five with their original contents
# @description: Creates five small text files (f0..f4), bundles them into a single tar.zst archive, extracts and asserts all five files are present with the expected contents — pinning libarchive's multi-member zst extraction on Ubuntu 24.04.
# @timeout: 60
# @tags: usage, archive, bsdtar, zstd, multi-file, r21
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src=$tmpdir/src
mkdir -p "$src"
for i in 0 1 2 3 4; do
    printf 'r21-file-%d-content\n' "$i" >"$src/f${i}.txt"
done

bsdtar --zstd -cf "$tmpdir/a.tar.zst" -C "$tmpdir" src

out=$tmpdir/out
mkdir -p "$out"
bsdtar --zstd -xf "$tmpdir/a.tar.zst" -C "$out"

count=$(find "$out/src" -maxdepth 1 -type f -name 'f*.txt' | wc -l)
[[ "$count" == "5" ]] || { printf 'expected 5 extracted files, got %s\n' "$count" >&2; ls -la "$out/src" >&2; exit 1; }
for i in 0 1 2 3 4; do
    expected="r21-file-${i}-content"
    grep -Fq "$expected" "$out/src/f${i}.txt" || { printf 'expected content "%s" in f%s.txt\n' "$expected" "$i" >&2; exit 1; }
done
