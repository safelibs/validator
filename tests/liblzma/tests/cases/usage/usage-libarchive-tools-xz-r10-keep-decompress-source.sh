#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-r10-keep-decompress-source
# @title: xz --keep --decompress preserves .xz file
# @description: Decompresses a .xz with xz --keep --decompress and asserts both the original .xz and the new plaintext file remain on disk and the decompressed bytes match the source.
# @timeout: 120
# @tags: usage, xz, keep, decompress
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'keep-decompress payload line one\nline two\n' >"$tmpdir/data.txt"
src_sha=$(sha256sum "$tmpdir/data.txt" | awk '{print $1}')
xz -z "$tmpdir/data.txt"

[[ -f "$tmpdir/data.txt.xz" ]]
[[ ! -f "$tmpdir/data.txt" ]]

xz --keep --decompress "$tmpdir/data.txt.xz"

[[ -f "$tmpdir/data.txt.xz" ]]
[[ -f "$tmpdir/data.txt" ]]

out_sha=$(sha256sum "$tmpdir/data.txt" | awk '{print $1}')
test "$src_sha" = "$out_sha"
