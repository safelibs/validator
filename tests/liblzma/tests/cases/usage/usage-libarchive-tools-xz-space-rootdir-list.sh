#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-space-rootdir-list
# @title: libarchive-tools xz spaced root list
# @description: Lists an xz-compressed tar whose top-level directory name contains spaces and verifies the nested path.
# @timeout: 180
# @tags: usage, archive, xz
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-libarchive-tools-xz-space-rootdir-list"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in/space root"
printf 'inner\n' >"$tmpdir/in/space root/inner.txt"
bsdtar -cJf "$tmpdir/a.tar.xz" -C "$tmpdir/in" 'space root'
bsdtar -tf "$tmpdir/a.tar.xz" | tee "$tmpdir/list"
validator_assert_contains "$tmpdir/list" 'space root/inner.txt'
