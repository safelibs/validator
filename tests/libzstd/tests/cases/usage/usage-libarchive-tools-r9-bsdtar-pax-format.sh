#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-r9-bsdtar-pax-format
# @title: bsdtar zstd writes pax-format archive
# @description: Creates a zstd-compressed tar in pax format with bsdtar --format=pax and verifies bsdtar -tvf can list the member.
# @timeout: 180
# @tags: usage, archive, zstd, pax
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in"
printf 'pax format payload\n' >"$tmpdir/in/file.txt"

bsdtar --zstd --format=pax -cf "$tmpdir/a.tar.zst" -C "$tmpdir/in" file.txt
bsdtar -tvf "$tmpdir/a.tar.zst" >"$tmpdir/list"

validator_assert_contains "$tmpdir/list" 'file.txt'

# Confirm zstd magic bytes.
magic=$(od -An -N4 -tx1 "$tmpdir/a.tar.zst" | tr -d ' \n')
test "$magic" = "28b52ffd"
