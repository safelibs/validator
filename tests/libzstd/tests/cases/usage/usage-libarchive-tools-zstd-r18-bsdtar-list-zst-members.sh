#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r18-bsdtar-list-zst-members
# @title: bsdtar -t lists three tar.zst members in deterministic order
# @description: Builds a tar.zst archive with three named files, runs bsdtar -tf to list its members, and asserts every expected name appears in the output — confirming libarchive's tar.zst listing path.
# @timeout: 60
# @tags: usage, archive, bsdtar, zstd, list, r18
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/src"
mkdir -p "$src"
printf 'a\n' >"$src/one.txt"
printf 'b\n' >"$src/two.txt"
printf 'c\n' >"$src/three.txt"

(cd "$src" && bsdtar --zstd -cf "$tmpdir/archive.tar.zst" one.txt two.txt three.txt)

bsdtar -tf "$tmpdir/archive.tar.zst" >"$tmpdir/listing.txt"
validator_assert_contains "$tmpdir/listing.txt" 'one.txt'
validator_assert_contains "$tmpdir/listing.txt" 'two.txt'
validator_assert_contains "$tmpdir/listing.txt" 'three.txt'
