#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-magic-default-level
# @title: bsdtar zstd default level frame magic
# @description: Verifies bsdtar --zstd at default level emits a zstd frame whose first four bytes are the 28 b5 2f fd magic number.
# @timeout: 180
# @tags: usage, archive, zstd
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in"
printf 'magic default level payload\n' >"$tmpdir/in/payload.txt"

bsdtar --zstd -cf "$tmpdir/a.tar.zst" -C "$tmpdir/in" payload.txt
validator_require_file "$tmpdir/a.tar.zst"

magic=$(od -An -N4 -tx1 "$tmpdir/a.tar.zst" | tr -d ' \n')
test "$magic" = "28b52ffd"

bsdtar -tf "$tmpdir/a.tar.zst" >"$tmpdir/list"
validator_assert_contains "$tmpdir/list" 'payload.txt'
