#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-space-rootdir-list
# @title: libarchive-tools zstd spaced root list
# @description: Lists a zstd-compressed tar whose top-level directory name contains spaces and verifies the nested path.
# @timeout: 180
# @tags: usage, archive, zstd
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-libarchive-tools-zstd-space-rootdir-list"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in/space root"
printf 'inner\n' >"$tmpdir/in/space root/inner.txt"
bsdtar --zstd -cf "$tmpdir/a.tar.zstd" -C "$tmpdir/in" 'space root'
bsdtar -tf "$tmpdir/a.tar.zstd" | tee "$tmpdir/list"
validator_assert_contains "$tmpdir/list" 'space root/inner.txt'
