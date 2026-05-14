#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r18-bsdtar-uname-gname-preserved
# @title: bsdtar --uname --gname embeds custom owner/group strings into a tar.zst archive
# @description: Packs a single file into tar.zst with bsdtar --uname=zguser --gname=zggroup, then asks bsdtar -tvf to list the archive in verbose mode and asserts both owner and group strings appear in the listing.
# @timeout: 60
# @tags: usage, archive, bsdtar, zstd, ownership, r18
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/src"
mkdir -p "$src"
printf 'owner-test\n' >"$src/payload.txt"

(cd "$src" && bsdtar --zstd --uname=zguser --gname=zggroup -cf "$tmpdir/archive.tar.zst" payload.txt)

bsdtar -tvf "$tmpdir/archive.tar.zst" >"$tmpdir/listing.txt"
validator_assert_contains "$tmpdir/listing.txt" 'zguser'
validator_assert_contains "$tmpdir/listing.txt" 'zggroup'
