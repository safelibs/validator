#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r21-bsdtar-extract-nested-tar-zst
# @title: bsdtar -x extracts a nested tar.zst that itself contains another tar.zst
# @description: Wraps a payload file in tar.zst inner archive, then wraps that inner archive into an outer tar.zst, extracts the outer archive and the inner archive in sequence, and asserts the final extracted payload matches the original bytes — pinning libarchive's nested-zst extraction on Ubuntu 24.04.
# @timeout: 120
# @tags: usage, archive, bsdtar, zstd, nested, r21
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src=$tmpdir/src
mkdir -p "$src"
printf 'r21 nested payload\n' >"$src/payload.txt"
expected=$(sha256sum "$src/payload.txt" | awk '{print $1}')

# Inner archive
bsdtar --zstd -cf "$tmpdir/inner.tar.zst" -C "$tmpdir" src
# Outer archive containing the inner archive
mkdir -p "$tmpdir/wrap"
cp "$tmpdir/inner.tar.zst" "$tmpdir/wrap/inner.tar.zst"
bsdtar --zstd -cf "$tmpdir/outer.tar.zst" -C "$tmpdir" wrap

# Extract outer, then inner.
out=$tmpdir/out
mkdir -p "$out"
bsdtar --zstd -xf "$tmpdir/outer.tar.zst" -C "$out"
[[ -s "$out/wrap/inner.tar.zst" ]]
final=$tmpdir/final
mkdir -p "$final"
bsdtar --zstd -xf "$out/wrap/inner.tar.zst" -C "$final"

actual=$(sha256sum "$final/src/payload.txt" | awk '{print $1}')
[[ "$expected" == "$actual" ]] || { printf 'sha mismatch: expected %s got %s\n' "$expected" "$actual" >&2; exit 1; }
