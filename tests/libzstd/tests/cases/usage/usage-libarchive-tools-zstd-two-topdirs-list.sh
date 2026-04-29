#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-two-topdirs-list
# @title: libarchive-tools zstd two topdirs list
# @description: Creates a zstd-compressed tar with two top-level directories and verifies both paths appear in the archive listing.
# @timeout: 180
# @tags: usage, archive, zstd
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-libarchive-tools-zstd-two-topdirs-list"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in/top1" "$tmpdir/in/top2"
printf 'alpha\n' >"$tmpdir/in/top1/alpha.txt"
printf 'beta\n' >"$tmpdir/in/top2/beta.txt"
bsdtar --zstd -cf "$tmpdir/a.tar.zstd" -C "$tmpdir/in" top1 top2
bsdtar -tf "$tmpdir/a.tar.zstd" | tee "$tmpdir/list"
validator_assert_contains "$tmpdir/list" 'top1/alpha.txt'
validator_assert_contains "$tmpdir/list" 'top2/beta.txt'
