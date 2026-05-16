#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r21-bsdtar-stdin-stream-roundtrip
# @title: bsdtar --zstd reads a tar.zst archive from stdin via redirected file input
# @description: Creates a tar.zst archive on disk via bsdtar --zstd, then extracts it by piping the file through stdin (bsdtar --zstd -xf - <archive), and asserts the extracted file's sha256 matches the source — pinning libarchive's stdin-driven tar.zst decode on Ubuntu 24.04.
# @timeout: 60
# @tags: usage, archive, bsdtar, zstd, stdin, decode, r21
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src=$tmpdir/src
mkdir -p "$src"
printf 'stdin-decode-r21\n' >"$src/payload.txt"
expected=$(sha256sum "$src/payload.txt" | awk '{print $1}')

bsdtar --zstd -cf "$tmpdir/a.tar.zst" -C "$tmpdir" src

out=$tmpdir/out
mkdir -p "$out"
bsdtar --zstd -xf - -C "$out" <"$tmpdir/a.tar.zst"
[[ -f "$out/src/payload.txt" ]]
actual=$(sha256sum "$out/src/payload.txt" | awk '{print $1}')
[[ "$expected" == "$actual" ]] || { printf 'sha mismatch: expected %s got %s\n' "$expected" "$actual" >&2; exit 1; }
