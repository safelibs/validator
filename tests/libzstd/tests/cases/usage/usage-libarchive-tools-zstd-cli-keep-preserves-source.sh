#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-cli-keep-preserves-source
# @title: zstd CLI -k preserves source on compress
# @description: Compresses a payload with the standalone zstd CLI using -k, asserts the original source file still exists with its sha256 unchanged, the .zst output carries the zstd magic, and the frame round-trips back to the same bytes.
# @timeout: 120
# @tags: usage, archive, zstd, cli
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/payload.txt"
printf 'keep-source payload\n' >"$src"
src_sum=$(sha256sum "$src" | awk '{print $1}')

zstd -q -k "$src"
validator_require_file "$src.zst"
# -k must leave the original input in place.
validator_require_file "$src"
post_sum=$(sha256sum "$src" | awk '{print $1}')
test "$src_sum" = "$post_sum"

magic=$(od -An -N4 -tx1 "$src.zst" | tr -d ' \n')
test "$magic" = "28b52ffd"

zstd -tq "$src.zst"
zstd -dq -c "$src.zst" >"$tmpdir/decoded.txt"
cmp "$src" "$tmpdir/decoded.txt"
