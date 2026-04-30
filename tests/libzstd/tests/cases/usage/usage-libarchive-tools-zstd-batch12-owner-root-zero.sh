#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-batch12-owner-root-zero
# @title: bsdtar zstd uid 0 / gid 0 records root labels
# @description: Creates a zstd-compressed tar with --uid 0, --gid 0, --uname root, --gname root and asserts that bsdtar -tvf reports the entry with root/root labels.
# @timeout: 180
# @tags: usage, archive, zstd, metadata
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in"
printf 'root-owned payload\n' >"$tmpdir/in/payload.txt"

bsdtar --zstd --uid 0 --gid 0 --uname root --gname root \
  -cf "$tmpdir/a.tar.zst" -C "$tmpdir/in" payload.txt
validator_require_file "$tmpdir/a.tar.zst"

magic=$(od -An -N4 -tx1 "$tmpdir/a.tar.zst" | tr -d ' \n')
test "$magic" = "28b52ffd"

bsdtar -tvf "$tmpdir/a.tar.zst" >"$tmpdir/list"
validator_assert_contains "$tmpdir/list" 'payload.txt'
validator_assert_contains "$tmpdir/list" 'root'

# A typical -tvf line for a root-owned entry contains "root root" (uname gname).
grep -Eq 'root[[:space:]]+root' "$tmpdir/list"
