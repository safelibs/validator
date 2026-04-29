#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-hidden-and-visible-list
# @title: libarchive-tools zstd hidden and visible list
# @description: Archives a hidden file and a visible file together in a zstd-compressed tar and verifies both entries appear in the listing.
# @timeout: 180
# @tags: usage, archive, zstd
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-libarchive-tools-zstd-hidden-and-visible-list"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in"
printf 'visible\n' >"$tmpdir/in/visible.txt"
printf 'hidden\n' >"$tmpdir/in/.hidden"
bsdtar --zstd -cf "$tmpdir/a.tar.zstd" -C "$tmpdir/in" .hidden visible.txt
bsdtar -tf "$tmpdir/a.tar.zstd" | tee "$tmpdir/list"
validator_assert_contains "$tmpdir/list" '.hidden'
validator_assert_contains "$tmpdir/list" 'visible.txt'
