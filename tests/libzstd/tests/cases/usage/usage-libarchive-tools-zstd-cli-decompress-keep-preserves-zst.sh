#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-cli-decompress-keep-preserves-zst
# @title: zstd CLI -d -k preserves the .zst on decompress
# @description: Compresses a payload, then decompresses it with the zstd CLI using -d -k and asserts the .zst input is preserved with its sha256 unchanged while the decoded output matches the original byte stream.
# @timeout: 120
# @tags: usage, archive, zstd, cli
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/payload.txt"
printf 'keep-zst payload\n' >"$src"
src_sum=$(sha256sum "$src" | awk '{print $1}')

zstd -q -k -o "$tmpdir/payload.zst" "$src"
validator_require_file "$tmpdir/payload.zst"
zst_sum=$(sha256sum "$tmpdir/payload.zst" | awk '{print $1}')

# Decompress to a sibling path with -d -k; the .zst input must remain.
zstd -dq -k -o "$tmpdir/decoded.txt" "$tmpdir/payload.zst"
validator_require_file "$tmpdir/payload.zst"
post_zst_sum=$(sha256sum "$tmpdir/payload.zst" | awk '{print $1}')
test "$zst_sum" = "$post_zst_sum"

validator_require_file "$tmpdir/decoded.txt"
cmp "$src" "$tmpdir/decoded.txt"
dst_sum=$(sha256sum "$tmpdir/decoded.txt" | awk '{print $1}')
test "$src_sum" = "$dst_sum"
