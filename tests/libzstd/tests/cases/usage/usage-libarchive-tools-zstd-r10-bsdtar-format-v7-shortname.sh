#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r10-bsdtar-format-v7-shortname
# @title: bsdtar zstd writes v7 short-name archive
# @description: Creates a zstd-compressed tar in the legacy V7 format using --format=v7, then asserts the zstd frame magic and that bsdtar can list and extract the short-named member back to a byte-identical file.
# @timeout: 180
# @tags: usage, archive, zstd, v7
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in" "$tmpdir/out"
printf 'v7 short payload\n' >"$tmpdir/in/short.txt"

bsdtar --zstd --format=v7 -cf "$tmpdir/a.tar.zst" -C "$tmpdir/in" short.txt
validator_require_file "$tmpdir/a.tar.zst"

magic=$(od -An -N4 -tx1 "$tmpdir/a.tar.zst" | tr -d ' \n')
test "$magic" = "28b52ffd"

bsdtar -tf "$tmpdir/a.tar.zst" >"$tmpdir/list"
validator_assert_contains "$tmpdir/list" 'short.txt'

bsdtar -xf "$tmpdir/a.tar.zst" -C "$tmpdir/out"
diff -q "$tmpdir/in/short.txt" "$tmpdir/out/short.txt"
